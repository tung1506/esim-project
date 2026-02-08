# iOS Universal Link Implementation

## 📋 Overview
This document describes the implementation of eSIM installation on iOS using Universal Links instead of `CTCellularPlanProvisioning`.

## 🎯 Goals
- **Android**: Keep existing direct installation logic ✅
- **iOS**: Use Universal Link to trigger system eSIM installation ✅
- **No Callbacks**: User manually returns to app after installation ✅
- **Unified API**: Same JavaScript interface for both platforms ✅

## 🏗️ Architecture

### Platform-Specific Flow

#### Android Flow (Unchanged)
```
HTML → JS Bridge → Android Native → CTCellularPlanProvisioning → Direct Install
```

#### iOS Flow (NEW)
```
HTML → JS Bridge → iOS Native → Universal Link → Safari/Chrome → iOS System eSIM Setup
```

## 🔧 Implementation Details

### 1. iOS Native Code (`FlutterEsimPlugin.swift`)

**Method: `installEsimProfile`**
- Receives activation code from Flutter
- Constructs Universal Link: `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata={code}`
- Opens link in external browser using `UIApplication.shared.open()`
- Returns `true` if browser opens successfully

**Method: `openUniversalLink`** (Optional, alias)
- Alternative entry point for explicit Universal Link opening
- Internally calls same logic as `installEsimProfile`

### 2. iOS WebView (`FlutterEsimWebViewFactory.swift`)

**JavaScript Bridge Injection:**
```javascript
window.FlutterEsimBridge = {
    isSupportESim: function() {
        // Always returns true for iOS
        return Promise.resolve({ success: true, supported: true });
    },
    
    installEsimProfile: function(activationCode) {
        // Sends message to native iOS
        // Opens Universal Link in browser
        return Promise.resolve({ 
            success: true, 
            message: 'Opening eSIM setup in browser...' 
        });
    }
};
```

**WKScriptMessageHandler:**
- Receives messages from JavaScript
- Handles `installEsimProfile` method
- Extracts activation code
- Opens Universal Link via `UIApplication.shared.open()`

### 3. HTML Page (`esim_purchase.html`)

**Universal Interface:**
- Single "Install eSIM" button
- Works seamlessly on both platforms
- Platform detection handled natively
- User enters activation code (format: `LPA:1$SMDP+_Address$Activation_Code`)

### 4. Dart Code (`flutter_esim_webview.dart`)

**No Changes Required:**
- Uses existing method channel
- Platform-specific logic handled in native code
- Single API: `installEsimProfile(activationCode)`

## 📱 User Experience

### iOS User Flow:
1. User opens WebView in `esim_webview_host` app
2. Loads `esim_purchase.html` page
3. User enters activation code
4. Clicks "Install eSIM" button
5. **Safari/Chrome opens** with Universal Link
6. **iOS System eSIM Setup** appears
7. User completes installation
8. User manually returns to app

### Android User Flow:
1. User opens WebView in `esim_webview_host` app
2. Loads `esim_purchase.html` page
3. User enters activation code
4. Clicks "Install eSIM" button
5. **Direct installation** via Android API
6. User sees system dialog
7. Installation completes within app

## 🔍 Universal Link Format

```
https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=LPA:1$SMDP+_Address$Activation_Code
```

**Example:**
```
https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=LPA:1$sm-dp.example.com$ABC123XYZ
```

## ✅ Testing

### iOS Testing:
1. Run app on iOS device (not simulator)
2. Open WebView
3. Enter valid activation code
4. Click "Install eSIM"
5. **Verify**: Safari/Chrome opens with Universal Link
6. **Verify**: iOS eSIM setup appears
7. Complete installation
8. Return to app manually

### Android Testing:
1. Run app on Android device
2. Open WebView
3. Enter valid activation code
4. Click "Install eSIM"
5. **Verify**: System dialog appears
6. Complete installation within app

## 📝 Code Changes Summary

### Modified Files:
1. **`flutter_esim/ios/Classes/FlutterEsimPlugin.swift`**
   - Updated `installEsimProfile` to open Universal Link
   - Added `openEsimUniversalLink` helper method
   - Returns `bool` instead of calling old API

2. **`flutter_esim/ios/Classes/FlutterEsimWebViewFactory.swift`**
   - Updated JS Bridge injection
   - Added `isSupportESim` method (always true)
   - Added `installEsimProfile` method to open Universal Link
   - Updated `WKScriptMessageHandler` to handle new methods

3. **`flutter_esim/lib/flutter_esim_webview.dart`**
   - Minor comment updates
   - Logic remains platform-agnostic

### Unchanged Files:
- Android native code (keeps existing logic)
- HTML page (works with both platforms)
- Platform interface (already had `openUniversalLink`)
- Method channel (already had required methods)

## 🚀 Benefits

1. **iOS Native Experience**: Uses Apple's recommended approach
2. **No Callbacks Needed**: System handles installation
3. **Simple Implementation**: Minimal code changes
4. **Backward Compatible**: Android logic unchanged
5. **Unified API**: Same JavaScript interface

## ⚠️ Limitations

1. **No Installation Status**: App doesn't know if user completed installation
2. **Manual Return**: User must switch back to app manually
3. **iOS 10+ Only**: Requires `UIApplication.shared.open()` API
4. **Browser Required**: Must have Safari/Chrome installed

## 🔄 Future Enhancements

- Add deep link to return to app after installation
- Show installation instructions in modal before opening browser
- Add "Return to App" button in HTML after triggering Universal Link
- Track app lifecycle to detect when user returns

## 📚 References

- [Apple eSIM Universal Links](https://developer.apple.com/documentation/uikit/uiapplication/1648685-open)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)
- [Universal Links Guide](https://developer.apple.com/ios/universal-links/)

---

**Implementation Date**: February 8, 2026
**Status**: ✅ Complete
**Tested**: Pending device testing
