# 🧪 Testing Guide - iOS Universal Link eSIM Installation

## Prerequisites

### iOS Testing:
- ✅ Real iOS device (iPhone XR or later with eSIM support)
- ✅ iOS 12.0 or later
- ✅ Valid eSIM activation code (LPA format)
- ✅ Internet connection
- ✅ Xcode for building iOS app

### Android Testing:
- ✅ Android device with eSIM support
- ✅ Valid eSIM activation code
- ✅ Internet connection

## 📱 iOS Test Steps

### Step 1: Build and Run App
```bash
cd esim_webview_host
flutter clean
flutter pub get
flutter run -d <ios_device_id>
```

### Step 2: Open WebView
1. App launches and shows main screen
2. WebView automatically loads `esim_purchase.html`
3. Check console logs for:
   ```
   ✅ iOS FlutterEsimBridge injected successfully
   Platform: iOS | Method: Universal Link
   ```

### Step 3: Test eSIM Support Check
1. Click "Check eSIM Support" button
2. **Expected Result**: 
   - ✅ "Great! Your device supports eSIM"
   - Console log: `Platform: iOS | Method: Universal Link`

### Step 4: Test eSIM Installation
1. Enter activation code in format:
   ```
   LPA:1$sm-dp.example.com$activation-code
   ```
   
2. Click "Install eSIM" button

3. **Expected Behavior**:
   - ✅ Safari/Chrome opens automatically
   - ✅ URL shows: `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=...`
   - ✅ iOS System eSIM setup appears
   - ✅ Console log: `📲 Opening eSIM Universal Link: https://...`

4. **Complete Installation in iOS System**:
   - Follow iOS system prompts
   - Confirm eSIM installation
   - Wait for activation

5. **Return to App**:
   - Manually switch back to `esim_webview_host` app
   - WebView should still be visible

### Step 5: Verify Installation
1. Go to iOS Settings → Cellular
2. Check for new eSIM profile
3. Verify activation status

## 🤖 Android Test Steps

### Step 1: Build and Run App
```bash
cd esim_webview_host
flutter clean
flutter pub get
flutter run -d <android_device_id>
```

### Step 2: Open WebView
1. App launches and shows main screen
2. WebView automatically loads `esim_purchase.html`
3. Check logcat for:
   ```
   ✅ FlutterEsimBridge injected successfully
   ```

### Step 3: Test eSIM Support Check
1. Click "Check eSIM Support" button
2. **Expected Result**: 
   - ✅ "Great! Your device supports eSIM" (if device supports)
   - ❌ "Sorry, your device does NOT support eSIM" (if not supported)

### Step 4: Test eSIM Installation
1. Enter activation code
2. Click "Install eSIM" button
3. **Expected Behavior**:
   - ✅ Android system dialog appears
   - ✅ Installation happens within app
   - ✅ No browser opens
   - ✅ Console log: `📲 Installing eSIM profile...`

## 🔍 Debug Console Output

### iOS Expected Logs:
```
📄 Page started: file:///...esim_purchase.html
✅ Page finished: file:///...esim_purchase.html
✅ iOS FlutterEsimBridge injected successfully
Platform: iOS | Method: Universal Link
🔍 JS Bridge called: isSupportESim
📲 JS Bridge called: installEsimProfile
📲 Opening eSIM Universal Link: https://esimsetup.apple.com/...
✅ Universal Link opened successfully
```

### Android Expected Logs:
```
📄 Page started: file:///...esim_purchase.html
✅ Page finished: file:///...esim_purchase.html
✅ FlutterEsimBridge injected successfully
🔍 JS Bridge called: isSupportESim
📲 JS Bridge called: installEsimProfile
📲 Installing eSIM profile...
✅ Installation result: true
```

## ❌ Troubleshooting

### iOS Issues:

**Problem: Browser doesn't open**
- Check iOS version (must be 10.0+)
- Check activation code format
- Check device restrictions (MDM, parental controls)
- Check console for error: `❌ Failed to open Universal Link`

**Problem: "Invalid URL" error**
- Verify activation code format: `LPA:1$...`
- Check for special characters
- Ensure no spaces in code

**Problem: Universal Link opens but no eSIM setup**
- Activation code may be invalid
- eSIM profile may not exist
- Network issue on carrier side

**Problem: Bridge not available**
- Check console for: `⚠️ Bridge not detected`
- Ensure WebView is using `WKWebView`
- Check JS injection timing

### Android Issues:

**Problem: "Device does not support eSIM"**
- Device may not have eSIM capability
- Check Android version (9.0+)
- Check OEM restrictions

**Problem: Installation fails**
- Activation code may be invalid
- Network connectivity issue
- Carrier restrictions

## 📊 Test Activation Codes

### Test Code Format:
```
LPA:1$sm-dp.example.com$activation-code-here
```

### Sample Test Codes:
**Note**: These are example formats. Use real codes from your eSIM provider.

```
LPA:1$sm-dp-plus.provider.com$CODE123ABC
LPA:1$sm-v4.prod.ondemandconnectivity.com$CONF-CODE-HERE
LPA:1$esim-go.com$1234567890ABCDEF
```

## ✅ Success Criteria

### iOS:
- [x] WebView loads successfully
- [x] JS Bridge injects without errors
- [x] Support check returns `true`
- [x] Install button opens Safari/Chrome
- [x] Universal Link URL is correct
- [x] iOS eSIM setup appears
- [x] User can complete installation
- [x] User can return to app

### Android:
- [x] WebView loads successfully
- [x] JS Bridge injects without errors
- [x] Support check detects device capability
- [x] Install button triggers system dialog
- [x] Installation completes within app
- [x] eSIM activates successfully

## 🎥 Recording Test Session

### iOS:
```bash
# Screen record iOS device
xcrun simctl io booted recordVideo ios_test.mp4

# Stop recording with Ctrl+C
```

### Android:
```bash
# Screen record Android device
adb shell screenrecord /sdcard/android_test.mp4

# Pull recording
adb pull /sdcard/android_test.mp4
```

## 📝 Test Report Template

```markdown
## Test Report

**Date**: YYYY-MM-DD
**Tester**: Name
**Device**: iPhone XR / Pixel 6

### iOS Test Results:
- [ ] App launches
- [ ] WebView loads
- [ ] Bridge injection succeeds
- [ ] Support check works
- [ ] Install opens browser
- [ ] Universal Link correct
- [ ] eSIM setup appears
- [ ] Installation completes

**Issues Found**: None / [Describe issues]

**Console Logs**:
```
[Paste relevant logs]
```

**Screenshots**: [Attach screenshots]

### Android Test Results:
- [ ] App launches
- [ ] WebView loads
- [ ] Bridge injection succeeds
- [ ] Support check works
- [ ] Install triggers dialog
- [ ] Installation completes

**Issues Found**: None / [Describe issues]

**Console Logs**:
```
[Paste relevant logs]
```

**Screenshots**: [Attach screenshots]
```

## 🚀 Next Steps After Testing

1. ✅ Verify both platforms work as expected
2. ✅ Document any edge cases found
3. ✅ Create issue tickets for bugs
4. ✅ Update documentation with findings
5. ✅ Prepare for production deployment

---

**Last Updated**: February 8, 2026
**Version**: 1.0.0
