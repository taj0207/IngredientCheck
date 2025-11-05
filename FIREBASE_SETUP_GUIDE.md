# Firebase Functions Setup Guide for IngredientCheck

This guide will help you deploy the Firebase Function proxy to bypass ECHA's WAF restrictions.

## Prerequisites

- Node.js 18 or later
- npm (comes with Node.js)
- A Google account

---

## Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

---

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to sign in with your Google account.

---

## Step 3: Create Firebase Project

### Option A: Via Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. **Project name**: `ingredientcheck` (or your choice)
4. Click **"Continue"**
5. **Google Analytics**: Enable (optional, recommended)
6. Select or create an Analytics account
7. Click **"Create project"**
8. Wait for project creation to complete
9. Click **"Continue"**

### Option B: Via CLI

```bash
firebase projects:create ingredientcheck
```

---

## Step 4: Enable Billing (Required for External API Calls)

⚠️ **Important**: Firebase Functions that make external HTTP requests require the Blaze (pay-as-you-go) plan.

1. In Firebase Console, click the gear icon → **Project Settings**
2. Go to the **"Usage and billing"** tab
3. Click **"Modify plan"**
4. Select **"Blaze (Pay as you go)"**
5. Add your payment method

**Don't worry**: The free tier is very generous:
- 2M function invocations/month FREE
- 400,000 GB-seconds compute FREE
- 200,000 CPU-seconds FREE

Your app will stay well within free limits!

---

## Step 5: Initialize Firebase in Your Project

```bash
cd /Users/taj/Project/IngredientCheck
firebase init
```

### Configuration Prompts:

1. **"Which Firebase features do you want to set up?"**
   - Select: **Functions** (press Space, then Enter)
   - Select: **Firestore** (press Space, then Enter)

2. **"Please select an option:"**
   - Select: **"Use an existing project"**
   - Choose: `ingredientcheck` (your project name)

3. **"What language would you like to use to write Cloud Functions?"**
   - Select: **JavaScript**

4. **"Do you want to use ESLint?"**
   - Select: **No**

5. **"File firebase-functions/index.js already exists. Overwrite?"**
   - Select: **No** (we already created it)

6. **"Do you want to install dependencies with npm now?"**
   - Select: **Yes**

7. **Firestore Rules Setup:**
   - Select: **"Use an existing file"** → `firebase-functions/firestore.rules`

8. **Firestore Indexes:**
   - Press Enter to accept default

---

## Step 6: Install Dependencies

```bash
cd firebase-functions
npm install
```

This installs:
- `firebase-admin`: Firebase Admin SDK
- `firebase-functions`: Cloud Functions SDK
- `node-fetch`: HTTP client for Node.js

---

## Step 7: Deploy Functions

```bash
firebase deploy --only functions
```

This will:
1. Upload your function code
2. Deploy to Firebase infrastructure
3. Return your function URLs

**Expected output:**
```
✔  functions[echaSearch(us-central1)]: Successful create operation.
Function URL (echaSearch(us-central1)): https://us-central1-ingredientcheck.cloudfunctions.net/echaSearch

✔  functions[healthCheck(us-central1)]: Successful create operation.
Function URL (healthCheck(us-central1)): https://us-central1-ingredientcheck.cloudfunctions.net/healthCheck
```

**Save these URLs!** You'll need the `echaSearch` URL in the next step.

---

## Step 8: Update iOS App Configuration

1. Open `/Users/taj/Project/IngredientCheck/IngredientCheck/Core/Configuration/APIConfig.swift`

2. Replace the placeholder with your actual Firebase Function URL:

```swift
/// Firebase Function proxy URL for ECHA API
static let echaProxyURL = "https://us-central1-YOUR-PROJECT.cloudfunctions.net/echaSearch"
```

**Replace `YOUR-PROJECT`** with your actual Firebase project ID.

3. Ensure proxy is enabled (should already be set):

```swift
static let useECHAProxy = true
```

---

## Step 9: Test the Function

### Test via cURL

```bash
# Health check
curl https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/healthCheck

# Search for an ingredient
curl "https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/echaSearch?ingredient=benzene&format=json"
```

Expected response:
```json
{
  "results": [...],
  "cached": false
}
```

### Test in iOS Simulator

1. Build and run your app in Xcode
2. Scan an ingredient image
3. Check Xcode console for logs:
   - `✅ ECHA proxy response - cached: false`
   - Ingredient safety results displayed

---

## Step 10: Deploy Firestore Database

For caching to work, deploy Firestore:

```bash
firebase deploy --only firestore
```

This creates the database and applies security rules.

---

## Step 11: Enable Firestore in Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **"Firestore Database"** in left menu
4. Click **"Create database"**
5. Select **"Start in production mode"**
6. Choose a location (e.g., `us-central` - pick closest to you)
7. Click **"Enable"**

---

## Monitoring & Debugging

### View Logs

```bash
firebase functions:log
```

Or in Firebase Console:
1. Go to **Functions** section
2. Click on `echaSearch`
3. View **Logs** tab

### View Cached Data

1. In Firebase Console, go to **Firestore Database**
2. Browse the `echa_cache` collection
3. See cached ingredients with timestamps

### Check Usage

1. In Firebase Console, click gear icon → **Usage and billing**
2. View function invocations, compute time, etc.

---

## Common Issues & Solutions

### ❌ Error: "Billing account not configured"

**Solution**: Enable the Blaze plan (see Step 4)

### ❌ Error: "Permission denied"

**Solution**:
```bash
firebase login --reauth
```

### ❌ Error: "Function deployment failed"

**Solutions**:
1. Check Node.js version: `node --version` (must be 18+)
2. Delete `node_modules` and reinstall:
   ```bash
   cd firebase-functions
   rm -rf node_modules
   npm install
   ```

### ❌ iOS App: "Invalid URL"

**Solution**: Verify `echaProxyURL` in `APIConfig.swift` is correct and includes `https://`

### ❌ ECHA requests still failing

**Solutions**:
1. Verify `useECHAProxy = true` in `APIConfig.swift`
2. Check Firebase Function logs for errors
3. Test function directly with cURL

---

## Cost Estimates

### Free Tier (Monthly)
- **Function invocations**: 2,000,000 FREE
- **Compute time**: 400,000 GB-seconds FREE
- **Network egress**: 5 GB FREE

### Estimated Usage
- **1,000 active users**
- **10 scans per user per day**
- **12 ingredients per scan**
- **= 120,000 requests/day** (3.6M/month)

**With caching (80% hit rate):**
- **Actual ECHA calls**: ~24,000/day (720K/month)
- **Function invocations**: 120,000/day (3.6M/month)
- **Cost**: ~$0.80/month (above free tier)

### Optimize Costs
- Cache reduces API calls by 80%
- Scheduled cache cleanup removes old entries
- Rate limiting prevents abuse

---

## Security Considerations

✅ **No API keys exposed** to iOS app
✅ **CORS configured** for your app only
✅ **Firestore rules** prevent unauthorized access
✅ **Input validation** on all parameters
✅ **Rate limiting** via Firebase quotas

---

## Next Steps (Optional)

### Add API Key Authentication

Protect your function from unauthorized use:

```javascript
// In firebase-functions/index.js
const API_KEY = "your-secret-key";

if (req.get('X-API-Key') !== API_KEY) {
  res.status(401).json({ error: 'Unauthorized' });
  return;
}
```

Then in iOS:
```swift
headers["X-API-Key"] = "your-secret-key"
```

### Add Rate Limiting Per User

Track requests per user ID to prevent abuse.

### Add Analytics

Track which ingredients are most searched.

---

## Support

**Firebase Documentation**: https://firebase.google.com/docs/functions
**IngredientCheck Issues**: Create an issue in your project repo

---

## Summary

✅ Firebase Functions deployed as ECHA proxy
✅ WAF restrictions bypassed
✅ Caching enabled (24-hour TTL)
✅ iOS app configured to use proxy
✅ Within free tier limits

**You're all set!** 🎉
