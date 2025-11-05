# How to Use IngredientCheck App

## 🚀 Running the App

1. **In Xcode**: Press **Cmd + R**
2. Wait for the simulator to reload
3. You should now see the **full app interface**

---

## 📱 App Interface Overview

The app has **3 main tabs** at the bottom:

### 1. 🏠 **Home Tab** (Default)

When you open the app, you'll see:

- **"Welcome back!"** heading
- **"Scan product labels to check ingredient safety"** subtitle
- **Two action cards:**
  - 🟢 **"Scan Label"** - Take a photo of ingredients
  - 🔵 **"Choose Photo"** - Select from your photo library

**What you can do:**
- Tap the green card to start scanning (but camera isn't fully implemented yet)
- Tap the blue card to choose a photo from your library
- View recent scans (if you have any)

---

### 2. 📷 **Scan Tab** (Middle)

This is where the main functionality happens:

**Features:**
- **Camera interface** for taking photos of ingredient labels
- **Photo picker** to choose existing images
- **OCR (Optical Character Recognition)** using GPT-5-mini to extract ingredients from photos
- **Safety analysis** of detected ingredients using the ECHA database

**How to use:**
1. Tap the **Scan tab** at the bottom
2. You'll see options to:
   - Take a photo (requires camera permission)
   - Choose from library (requires photo permission)
3. After selecting an image:
   - The app sends it to GPT-5-mini for ingredient extraction
   - Then checks each ingredient against the ECHA safety database
   - Shows results with safety ratings (Safe 🟢, Caution 🟡, Warning 🟠, Danger 🔴)

**Note:** This uses your OpenAI API key and costs approximately **$0.001 per scan**.

---

### 3. 🕐 **History Tab** (Right)

View all your previous scans:

**Features:**
- List of all past ingredient scans
- Each entry shows:
  - Product name (if detected)
  - Number of ingredients found
  - Overall safety rating
  - Date and time of scan
- Tap any scan to see detailed results
- Swipe left to delete old scans

**How to use:**
1. Tap the **History tab**
2. Browse your scan history
3. Tap any item to view full details
4. Pull down to refresh

---

## 🎯 How to Scan Ingredients

### Method 1: Using Camera (on Real Device)

1. Go to **Scan tab**
2. Tap **"Take Photo"** or camera button
3. Allow camera permission if prompted
4. Point camera at ingredient list on product
5. Take photo when ingredients are clear and readable
6. Wait for processing (5-10 seconds)
7. View results!

### Method 2: Using Photo Library (Works on Simulator)

1. Go to **Scan tab**
2. Tap **"Choose from Library"** or photo button
3. Allow photo library access if prompted
4. Select a photo with ingredient text
5. Wait for OCR processing
6. View safety analysis!

**Tips for Best Results:**
- ✅ Good lighting
- ✅ Clear, focused image
- ✅ Ingredient list fills most of the frame
- ✅ Text is horizontal and not at an angle
- ❌ Avoid blurry or low-resolution images

---

## 🔬 Understanding Safety Ratings

The app shows safety levels for each ingredient:

| Color | Rating | Meaning |
|-------|--------|---------|
| 🟢 Green | **Safe** | No known hazards, safe for use |
| 🟡 Yellow | **Caution** | Minor concerns, generally safe |
| 🟠 Orange | **Warning** | Some hazards identified, use with care |
| 🔴 Red | **Danger** | Significant hazards, avoid if possible |
| ⚪ Gray | **Unknown** | No data available in ECHA database |

---

## 🛠️ Current Limitations

### ✅ What Works:
- Home screen with action cards
- Tab navigation
- Basic UI layout
- OpenAI API integration (configured)
- ECHA database client (configured)

### ⚠️ What's Not Fully Implemented Yet:
- **Camera capture** - UI exists but needs testing on real device
- **OCR processing** - Configured but needs actual image input
- **Scan history persistence** - Currently stores in memory only
- **Detailed ingredient info** - Basic view exists
- **Sign in with Apple** - Placeholder only
- **Google Sign In** - Not configured

### 🔧 To Test on Real Device:
You'll need to:
1. Connect iPhone via USB
2. In Xcode → Signing & Capabilities
3. Select your Team (Apple ID)
4. Build to device (Cmd + R)
5. Trust the app on your phone (Settings → General → Device Management)

---

## 🎨 Current Features in Detail

### Home Screen Actions

**"Scan Label" Card (Green):**
- Purpose: Quick access to camera scanning
- Status: UI ready, camera needs real device
- Tap to: Open camera interface

**"Choose Photo" Card (Blue):**
- Purpose: Select existing photos to analyze
- Status: UI ready, needs photo picker integration
- Tap to: Open photo library

### Scan Results View

After scanning, you'll see:
- **Product name** (if detected from image)
- **Overall safety rating** (worst ingredient determines this)
- **List of ingredients** with individual ratings
- **Number of concerns** found
- **Processing time** (OCR + safety checks)

### Detail View

Tap any ingredient to see:
- **Hazard statements** (H-codes like H302, H350)
- **Precautionary statements** (P-codes)
- **GHS classifications** (pictograms)
- **Regulatory status** (approved/restricted/banned)
- **Sources** (ECHA, IARC, etc.)

---

## 💡 Testing the App

### Option 1: With Sample Data

The app includes sample ingredients:
- `Ingredient.sampleSafe` - A safe ingredient (e.g., Water)
- `Ingredient.sampleWarning` - Mild concern (e.g., Parabens)
- `Ingredient.sampleDanger` - High risk (e.g., Formaldehyde)

You could modify the code to show these samples in the history tab for testing.

### Option 2: With Real Photos

1. Find a product with an ingredient list
2. Take a clear photo
3. Save to your computer
4. Drag into iOS Simulator (Photos app)
5. Use the app to select that photo

### Option 3: On Real iPhone

1. Build to your device
2. Take real photos of products
3. Test camera permission flow
4. Test full scanning workflow

---

## 📊 Costs & API Usage

**OpenAI GPT-5-mini:**
- Cost: ~$0.001 per scan (0.1 cents)
- Usage: Only when scanning images
- Your monthly limit depends on your OpenAI account

**ECHA Database:**
- Cost: FREE ✅
- Usage: No limits
- Public EU chemical safety database

**Total cost for 1000 scans:** ~$1.00

---

## 🐛 Troubleshooting

### App shows "No ingredients found"
- Image quality is too poor
- Ingredient text is too small
- Photo doesn't contain readable text
- OCR failed (check API key)

### "API Error" message
- Check your OpenAI API key in `Secrets.swift`
- Verify you have API credits
- Check internet connection

### Camera doesn't work
- Must test on real device (simulator has no camera)
- Grant camera permission when prompted
- Check Settings → Privacy → Camera

### Results seem wrong
- ECHA database may not have data for all ingredients
- Common names vs. chemical names may differ
- Some ingredients may not be in EU database

---

## 🔄 Next Steps to Complete the App

1. **Test camera functionality** on real device
2. **Implement photo picker** properly
3. **Connect OCR service** to process actual images
4. **Add scan history persistence** (CoreData or UserDefaults)
5. **Polish UI/UX** with loading states
6. **Add error handling** for failed scans
7. **Implement sharing** of scan results
8. **Add localization** (Traditional Chinese + English)

---

## 📞 Need Help?

If something doesn't work:
1. Check the Xcode console for errors (Cmd + Shift + Y)
2. Verify your OpenAI API key is correct
3. Ensure you're connected to internet
4. Try rebuilding (Cmd + Shift + K, then Cmd + R)

The app architecture is ready - most features are implemented but need integration testing!
