/**
 * Firebase Functions for IngredientCheck
 * Proxy for PubChem API to get ingredient safety information
 */

const functions = require('firebase-functions');
const fetch = require('node-fetch');

/**
 * PubChem API Proxy Function
 *
 * Endpoint: https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch
 *
 * Query Parameters:
 * - ingredient: Ingredient name to search (required)
 * - format: Response format (ignored, always returns JSON)
 *
 * Example:
 * GET /echaSearch?ingredient=benzene&format=json
 */
exports.echaSearch = functions.https.onRequest(async (req, res) => {
  // Enable CORS for iOS app
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Only allow GET requests
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const ingredient = req.query.ingredient;

    // Validate input
    if (!ingredient) {
      res.status(400).json({ error: 'Missing required parameter: ingredient' });
      return;
    }

    console.log(`Searching PubChem for: ${ingredient}`);

    // Step 1: Search PubChem for compound by name to get CID
    const searchUrl = `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/${encodeURIComponent(ingredient)}/JSON`;

    const searchResponse = await fetch(searchUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      },
      timeout: 10000
    });

    if (!searchResponse.ok) {
      console.log(`PubChem search failed for '${ingredient}': ${searchResponse.status}`);
      // Return empty results if not found
      res.status(200).json({ results: [] });
      return;
    }

    const searchData = await searchResponse.json();

    if (!searchData.PC_Compounds || searchData.PC_Compounds.length === 0) {
      console.log(`No compounds found for '${ingredient}'`);
      res.status(200).json({ results: [] });
      return;
    }

    // Get the first compound's CID
    const cid = searchData.PC_Compounds[0].id.id.cid;
    console.log(`Found CID ${cid} for '${ingredient}'`);

    // Step 2: Get compound properties (name, formula, etc.)
    const propertyUrl = `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/${cid}/property/Title,MolecularFormula,IUPACName/JSON`;

    const propertyResponse = await fetch(propertyUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      },
      timeout: 10000
    });

    let compoundName = ingredient;
    let molecularFormula = '';

    if (propertyResponse.ok) {
      const propertyData = await propertyResponse.json();
      if (propertyData.PropertyTable && propertyData.PropertyTable.Properties.length > 0) {
        const props = propertyData.PropertyTable.Properties[0];
        compoundName = props.Title || ingredient;
        molecularFormula = props.MolecularFormula || '';
      }
    }

    // Step 3: Get GHS classification (safety data)
    const ghsUrl = `https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/${cid}/JSON/?response_type=display&heading=GHS+Classification`;

    const ghsResponse = await fetch(ghsUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      },
      timeout: 10000
    });

    let ghsData = null;
    if (ghsResponse.ok) {
      ghsData = await ghsResponse.json();
      console.log(`Successfully fetched GHS data for CID ${cid}`);
    } else {
      console.log(`No GHS data available for CID ${cid}`);
    }

    // Format response to match ECHA-like structure
    const result = {
      id: `pubchem_${cid}`,
      name: compoundName,
      cas: null,  // PubChem has this but in a different endpoint
      ec: null,
      cid: cid,
      molecularFormula: molecularFormula,
      ghsData: ghsData ? parseGHSData(ghsData) : null
    };

    console.log(`Successfully processed: ${ingredient}`);

    // Return in ECHA-compatible format
    res.status(200).json({
      results: [result]
    });

  } catch (error) {
    console.error('Error in echaSearch:', error);

    // Return appropriate error
    if (error.code === 'ETIMEDOUT' || error.type === 'request-timeout') {
      res.status(504).json({ error: 'PubChem API timeout' });
    } else {
      res.status(500).json({ error: 'Internal server error', details: error.message });
    }
  }
});

/**
 * Parse GHS data from PubChem response
 */
function parseGHSData(ghsResponse) {
  try {
    if (!ghsResponse.Record || !ghsResponse.Record.Section) {
      return null;
    }

    const ghsSection = findGHSSection(ghsResponse.Record.Section);
    if (!ghsSection || !ghsSection.Information) {
      return null;
    }

    const ghsInfo = {
      pictograms: [],
      signal: null,
      hazardStatements: [],
      precautionaryStatements: []
    };

    // Parse each information item
    for (const info of ghsSection.Information) {
      const name = info.Name;
      const value = info.Value;

      if (!value || !value.StringWithMarkup) continue;

      if (name === 'Pictogram(s)' && value.StringWithMarkup[0].Markup) {
        // Extract pictogram URLs
        for (const markup of value.StringWithMarkup[0].Markup) {
          if (markup.Type === 'Icon' && markup.Extra) {
            ghsInfo.pictograms.push({
              name: markup.Extra,
              url: markup.URL
            });
          }
        }
      } else if (name === 'Signal') {
        ghsInfo.signal = value.StringWithMarkup[0].String;
      } else if (name === 'GHS Hazard Statements') {
        // Parse hazard statements (multiple StringWithMarkup entries)
        for (const statement of value.StringWithMarkup) {
          ghsInfo.hazardStatements.push(statement.String);
        }
      } else if (name === 'Precautionary Statement Codes') {
        // Parse precautionary statements
        for (const statement of value.StringWithMarkup) {
          ghsInfo.precautionaryStatements.push(statement.String);
        }
      }
    }

    return ghsInfo;
  } catch (error) {
    console.error('Error parsing GHS data:', error);
    return null;
  }
}

/**
 * Recursively find GHS Classification section
 */
function findGHSSection(sections) {
  for (const section of sections) {
    if (section.TOCHeading === 'GHS Classification') {
      return section;
    }
    if (section.Section) {
      const found = findGHSSection(section.Section);
      if (found) return found;
    }
  }
  return null;
}

/**
 * Health Check Endpoint
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'IngredientCheck Firebase Functions (PubChem)',
    api: 'PubChem REST API'
  });
});
