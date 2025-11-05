# IngredientCheck Testing Guide

This guide walks you through testing the complete flow after deploying Firebase Functions.

## Prerequisites

Before testing:
- ✅ Firebase Functions deployed successfully
- ✅ Firestore database enabled
- ✅ `echaProxyURL` updated in `APIConfig.swift` with your actual function URL
- ✅ App built and ready to run

---

## Phase 1: Firebase Function Testing (Backend)

### 1.1 Health Check Test

Test that the function is deployed and accessible:

```bash
curl https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/healthCheck
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-05T12:34:56.789Z",
  "service": "IngredientCheck Firebase Functions"
}
```

**If this fails:**
- Verify function URL is correct
- Check Firebase Console → Functions → ensure function is deployed
- Check function logs: `firebase functions:log`

### 1.2 ECHA Proxy Test (First Request - No Cache)

Test ingredient lookup without cache:

```bash
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=benzene&format=json"
```

**Expected Response:**
```json
{
  "results": [
    {
      "id": "100.000.753",
      "name": "benzene",
      "cas": "71-43-2",
      "ec": "200-753-7"
    }
  ],
  "cached": false
}
```

**What to check:**
- Response includes `results` array
- `cached: false` on first request
- Response time: 2-5 seconds (direct ECHA call)

### 1.3 ECHA Proxy Test (Second Request - With Cache)

Run the same request again immediately:

```bash
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=benzene&format=json"
```

**Expected Response:**
```json
{
  "results": [...],
  "cached": true,
  "cacheAge": 0
}
```

**What to check:**
- `cached: true` on second request
- `cacheAge` shows time since first request (in minutes)
- Response time: < 500ms (from cache)

### 1.4 Test Multiple Ingredients

Test with different ingredients to verify lookup works:

```bash
# Test with common ingredient
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=water&format=json"

# Test with preservative
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=sodium%20benzoate&format=json"

# Test with colorant
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=tartrazine&format=json"
```

### 1.5 Verify Firestore Cache

Check that data is being cached in Firestore:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** in left menu
4. Look for `echa_cache` collection
5. You should see documents with keys like `echa_benzene`, `echa_water`, etc.

**Each document should contain:**
```json
{
  "ingredient": "benzene",
  "data": { ... },
  "timestamp": 1730812345678
}
```

---

## Phase 2: iOS App Testing (Frontend)

### 2.1 Verify Configuration

Before running the app, verify:

```swift
// In APIConfig.swift
static let useECHAProxy = true  // ✅ Must be true
static let echaProxyURL = "https://YOUR-ACTUAL-URL.cloudfunctions.net/echaSearch"  // ✅ Real URL
```

### 2.2 Build and Run App

```bash
# Build for simulator
xcodebuild -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Or open in Xcode and press Cmd+R
open IngredientCheck.xcodeproj
```

### 2.3 Test Camera Permission

1. Launch app
2. Grant camera permission when prompted
3. Verify camera preview shows

**If camera fails:**
- Check `Info.plist` has `NSCameraUsageDescription`
- Verify device has camera (not simulator limitation)
- Check console for permission errors

### 2.4 Test Photo Library Selection

1. Tap photo library button
2. Select a product label image with ingredients
3. Wait for OCR processing

**Expected Console Logs:**
```
🎯 Processing image for OCR...
📊 API Response - Model: gpt-5, Choices: 1
📊 Token Usage - Prompt: X, Completion: Y, Total: Z
✅ Successfully parsed N ingredients from JSON
```

**If OCR fails:**
- Check OpenAI API key in `Secrets.swift`
- Verify `maxOCRTokens = 4096` in `APIConfig.swift`
- Check console for `finish_reason: "stop"` (not "length")

### 2.5 Test ECHA Safety Lookup

After OCR extracts ingredients, app should automatically look up safety info:

**Expected Console Logs:**
```
🔍 Fetching ECHA data for: sugar
✅ ECHA proxy response - cached: false
✅ ECHA query for 'sugar' - found: true

🔍 Fetching ECHA data for: palm oil
✅ ECHA proxy response - cached: true
✅ ECHA query for 'palm oil' - found: true
```

**What to verify:**
- Each ingredient shows safety level (Safe/Caution/Warning/Danger)
- First lookup: `cached: false`
- Subsequent lookups: `cached: true`
- UI displays results correctly

### 2.6 Test Complete Scan Flow

**Full end-to-end test:**

1. **Capture/Select Image**
   - Use camera or photo library
   - Select image with ingredient list

2. **Verify OCR Extraction**
   - Check console for parsed ingredients
   - Verify ingredients appear in UI

3. **Verify ECHA Lookups**
   - Check console for ECHA queries
   - Verify safety info appears for each ingredient

4. **Verify Results Display**
   - Each ingredient shows name
   - Safety badge shows correct level
   - Can tap ingredient for details

5. **Test Scan History**
   - Previous scan appears in history
   - Can tap to view past results
   - Data persists after app restart

---

## Phase 3: Error Handling Tests

### 3.1 Test Network Offline

1. Turn off WiFi/cellular on device
2. Try to scan an image
3. Verify error message appears
4. Turn network back on
5. Retry should work

### 3.2 Test Invalid Image

1. Select image with no text
2. Verify graceful error handling
3. User should see helpful message

### 3.3 Test API Rate Limiting

If you hit rate limits:
- OpenAI: Wait 1 minute, retry
- ECHA: Cache should prevent this

### 3.4 Test Invalid Ingredient Names

1. Manually trigger lookup with nonsense ingredient
2. Verify app handles "not found" gracefully
3. UI should show "Unknown" or similar state

---

## Phase 4: Performance Tests

### 4.1 Test Caching Performance

**First scan of new product:**
- Note total time from capture to results

**Second scan of same product:**
- Should be significantly faster (cache hit)
- Check console for `cached: true`

### 4.2 Test Multiple Ingredients

Use product with 10+ ingredients:
- All should process concurrently
- Check for parallel ECHA requests in logs
- Total time should be < 10 seconds

### 4.3 Test Memory Usage

1. Open Xcode Memory Gauge
2. Perform 10 scans in a row
3. Verify memory doesn't continuously increase
4. Check for memory leaks with Instruments

---

## Phase 5: Firebase Monitoring

### 5.1 Check Function Invocations

1. Go to Firebase Console → Functions
2. Click on `echaSearch` function
3. View metrics:
   - Invocation count
   - Execution time (should be < 2s for cache hits)
   - Error rate (should be < 5%)

### 5.2 Check Function Logs

```bash
# Via CLI
firebase functions:log --limit 50

# Or in Firebase Console
Functions → echaSearch → Logs tab
```

**Look for:**
- `Cache hit for: <ingredient>` (frequent)
- No errors or timeouts
- Successful ECHA API calls

### 5.3 Monitor Firestore Usage

1. Firebase Console → Firestore Database
2. View `echa_cache` collection size
3. Should grow with unique ingredients
4. Old entries should be cleaned up daily

### 5.4 Check Costs

1. Firebase Console → Usage and billing
2. Verify within free tier:
   - Function invocations: < 2M/month
   - Firestore reads/writes: < 50K/day
   - Network egress: < 1GB/month

---

## Troubleshooting Checklist

### ❌ "Invalid URL" Error

**Cause**: `echaProxyURL` not updated or incorrect

**Fix**:
1. Check `APIConfig.swift` line 53
2. Ensure URL matches Firebase deployment output
3. Verify URL includes `https://` and path `/echaSearch`

### ❌ "ECHA proxy search failed" Error

**Cause**: Firebase Function not deployed or failing

**Fix**:
1. Test function directly with cURL (see Phase 1)
2. Check Firebase Function logs: `firebase functions:log`
3. Verify Firestore is enabled
4. Check billing is enabled (required for external API calls)

### ❌ "JSON parsing failed" Error

**Cause**: GPT-5 response truncated or malformed

**Fix**:
1. Verify `maxOCRTokens = 4096` in `APIConfig.swift`
2. Check console for `finish_reason: "stop"` (not "length")
3. Review raw LLM response in console logs
4. Try with clearer/simpler ingredient list image

### ❌ Ingredients Not Found in ECHA

**Cause**: Ingredient name doesn't match ECHA database

**Expected**: This is normal for some ingredients
- Brand names won't be found
- Trade names need translation to chemical names
- Some food ingredients not in ECHA (cosmetics focus)

**Fix**: This is expected behavior, not a bug

### ❌ Slow Performance

**Cause**: Cache not working or poor network

**Fix**:
1. Verify Firestore caching works (see Phase 1.3)
2. Check network connection
3. Monitor Firebase Function execution time
4. Consider using closer Firebase region

---

## Success Criteria

✅ **Backend Tests Pass:**
- Health check returns 200
- ECHA proxy returns results
- Caching works (cached: true on second request)
- Firestore contains cached data

✅ **iOS App Works:**
- Camera/photo picker accessible
- OCR extracts ingredients correctly
- ECHA lookups succeed
- Results display in UI
- Scan history persists

✅ **Performance Acceptable:**
- First scan: < 10 seconds total
- Cached scans: < 3 seconds
- No memory leaks
- No crashes

✅ **Monitoring Shows Health:**
- Function invocations successful
- Logs show no errors
- Costs within free tier
- Cache hit rate > 50%

---

## Next Steps After Testing

Once all tests pass:

1. **Production Preparation**:
   - Add API key authentication to Firebase Function
   - Set up Firebase Analytics
   - Configure error reporting (Crashlytics)
   - Set up A/B testing for features

2. **App Store Submission**:
   - Add Privacy Policy
   - Complete App Store metadata
   - Take screenshots
   - Submit for review

3. **Monitoring & Maintenance**:
   - Set up alerts for function errors
   - Monitor daily costs
   - Track cache hit rate
   - Update ingredient database regularly

---

## Support

If you encounter issues not covered in this guide:

1. Check Firebase Function logs: `firebase functions:log`
2. Check Xcode console for app logs
3. Review `FIREBASE_SETUP_GUIDE.md` for deployment steps
4. Test each component in isolation (Phase 1, then Phase 2)
5. Verify all configuration values match deployment output

**Common Configuration Issues:**
- Wrong `echaProxyURL` → Test with cURL first
- `useECHAProxy = false` → Must be true
- Missing OpenAI API key → Check `Secrets.swift`
- Firestore not enabled → Enable in Firebase Console
- Billing not enabled → Required for external API calls
