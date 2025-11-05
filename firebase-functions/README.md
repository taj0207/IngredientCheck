# IngredientCheck Firebase Functions

Firebase Functions proxy for ECHA API to bypass Web Application Firewall restrictions.

## Setup

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name: `ingredientcheck` (or your choice)
4. Enable Google Analytics (optional)
5. Create project

### 4. Initialize Firebase in Your Project

```bash
cd /Users/taj/Project/IngredientCheck
firebase init
```

Select:
- Functions (use existing code in `firebase-functions/`)
- Firestore (for caching)

When prompted:
- Choose "Use an existing project" → select your project
- Language: JavaScript
- ESLint: No (optional)
- Install dependencies: Yes

### 5. Install Dependencies

```bash
cd firebase-functions
npm install
```

### 6. Deploy Functions

```bash
firebase deploy --only functions
```

After deployment, you'll get URLs like:
```
✔  functions[echaSearch(us-central1)]: https://us-central1-YOUR-PROJECT.cloudfunctions.net/echaSearch
✔  functions[healthCheck(us-central1)]: https://us-central1-YOUR-PROJECT.cloudfunctions.net/healthCheck
```

## Usage

### Test the Function

```bash
# Health check
curl https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/healthCheck

# Search for an ingredient
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=benzene&format=json"
```

### iOS App Integration

Update your iOS app's `APIConfig.swift`:

```swift
// Replace direct ECHA URL with Firebase Function URL
static let echaProxyURL = "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch"
```

## Features

✅ **WAF Bypass**: Server-side requests avoid bot detection
✅ **Caching**: 24-hour cache in Firestore reduces API calls
✅ **Rate Limiting**: Automatic via Firebase Functions quotas
✅ **CORS Support**: Allows iOS app to call the function
✅ **Error Handling**: Proper HTTP status codes
✅ **Auto-scaling**: Handles traffic spikes automatically

## Cost Estimate

**Free Tier Includes:**
- 2M function invocations/month
- 400,000 GB-seconds compute time
- 200,000 CPU-seconds
- 5GB network egress

**Typical Usage:**
- 1,000 users × 10 scans/day × 12 ingredients = 120,000 requests/day
- With caching, reduces to ~40,000 actual ECHA calls/day
- Well within free tier!

## Monitoring

View logs:
```bash
firebase functions:log
```

View in Firebase Console:
1. Go to Functions section
2. Click on function name
3. View logs, metrics, errors

## Local Development

Test locally with emulator:
```bash
cd firebase-functions
npm run serve
```

Then test at `http://localhost:5001/YOUR-PROJECT/us-central1/echaSearch`

## Security

- ✅ CORS restricted to your app (update if needed)
- ✅ Input validation on all parameters
- ✅ Firestore rules prevent unauthorized access
- ✅ Rate limiting via Firebase quotas
- ✅ No API keys exposed to client

## Troubleshooting

**"Functions deployment failed"**
- Check Node.js version (must be 18)
- Ensure billing is enabled (required for external API calls)

**"ECHA API timeout"**
- Function timeout is 15 seconds (configurable)
- Cache reduces load on ECHA API

**"Cache not working"**
- Check Firestore permissions in Firebase Console
- Verify cache TTL in function code

## Next Steps

1. Add rate limiting per user (if needed)
2. Add API key authentication for iOS app
3. Implement batch ingredient lookup
4. Add analytics for popular ingredients
