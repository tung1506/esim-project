# 🔍 Platform Detection Guide

## Overview

This document explains how the `esim_purchase.html` page automatically detects the platform (iOS/Android) and adapts the user experience accordingly.

## 🎯 How It Works

### 1. **User Agent Detection**

```javascript
function detectPlatform() {
    const ua = navigator.userAgent;
    if (/iPhone|iPad|iPod/i.test(ua)) {
        return 'iOS';
    } else if (/Android/i.test(ua)) {
        return 'Android';
    } else if (/Macintosh|Mac OS X/i.test(ua)) {
        return 'iOS'; // iPad in desktop mode
    }
    return 'Unknown';
}
```

### 2. **Platform-Specific Bridge Injection**

Both platforms inject the **same API** but with different implementations:

#### iOS (WKWebView):
```javascript
window.FlutterEsimBridge = {
    isSupportESim: function() {
        // Always returns true for iOS
    },
    installEsimProfile: function(activationCode) {
        // Opens Universal Link in Safari/Chrome
    }
}
```

#### Android (WebView):
```javascript
window.FlutterEsimBridge = {
    isSupportESim: function() {
        // Checks device capability
    },
    installEsimProfile: function(activationCode) {
        // Direct installation via Android API
    }
}
```

### 3. **Unified JavaScript API**

HTML page calls the **same method** regardless of platform:

```javascript
const result = await FlutterEsimBridge.installEsimProfile(code);
```

Native code handles platform-specific logic:
- **iOS**: Opens `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata={code}`
- **Android**: Calls `CTCellularPlanProvisioning`

## 📱 User Experience Differences

### iOS:
1. User enters activation code
2. Clicks "Install eSIM"
3. **Safari/Chrome automatically opens**
4. iOS System eSIM setup appears
5. User completes installation in iOS Settings
6. **User manually returns to app**

Success Message:
```
✅ Opening eSIM setup in browser. Please complete the installation and return to the app.
🍎 iOS: Safari/Chrome will open. Please complete installation and return to app.
```

### Android:
1. User enters activation code
2. Clicks "Install eSIM"
3. **System dialog appears within app**
4. User completes installation
5. **Stays in app**

Success Message:
```
✅ eSIM installation initiated successfully
🤖 Android: Follow the system prompts to complete installation.
```

## 🖥️ Platform Indicator

The page footer shows:
```
🍎 Platform: iOS | Method: Universal Link
```
or
```
🤖 Platform: Android | Method: Direct Installation
```

## 🔧 Implementation Details

### HTML Changes:

#### 1. **Platform Detection Function**
```javascript
let detectedPlatform = 'Unknown';

function detectPlatform() {
    const ua = navigator.userAgent;
    // ... detection logic
}
```

#### 2. **Update Platform Info Display**
```javascript
function updatePlatformInfo(platform, method) {
    const platformInfo = document.getElementById('platformInfo');
    const icon = platform === 'iOS' ? '🍎' : '🤖';
    platformInfo.innerHTML = `${icon} Platform: ${platform} | Method: ${method}`;
}
```

#### 3. **Platform-Specific Success Messages**
```javascript
if (result.success) {
    const installMethodMsg = detectedPlatform === 'iOS' ? 
        '🍎 iOS: Safari/Chrome will open...' :
        '🤖 Android: Follow the system prompts...';
    // Display message
}
```

## 📊 Console Logs

### iOS Logs:
```
🔍 Detected platform: iOS
User Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)...
✅ Page loaded successfully
✅ Bridge detected for iOS (Universal Link)
📲 Installing eSIM with code: LPA:1$...
✅ Opening eSIM setup in browser. Please complete the installation and return to the app.
```

### Android Logs:
```
🔍 Detected platform: Android
User Agent: Mozilla/5.0 (Linux; Android 13; Pixel 6)...
✅ Page loaded successfully
✅ Bridge detected for Android (Direct Installation)
📲 Installing eSIM with code: LPA:1$...
✅ eSIM installation initiated successfully
```

## ✅ No Code Changes Required in esim_webview_host

The `esim_webview_host` app does **not need any changes** because:

1. ✅ It uses `FlutterEsimWebView` widget from SDK
2. ✅ SDK handles all platform-specific logic
3. ✅ HTML page auto-detects platform
4. ✅ Bridge API is unified across platforms

**File: `esim_webview_host/lib/webview_page.dart`**
```dart
// No changes needed - works for both iOS and Android
return FlutterEsimWebView(
  initialUrl: url,
  onPageStarted: (url) { ... },
  onPageFinished: (url) { ... },
  onError: (error) { ... },
);
```

## 🧪 Testing Platform Detection

### iOS Test:
```bash
flutter run -d <iphone_device>
```

Expected footer:
```
🍎 Platform: iOS | Method: Universal Link
```

### Android Test:
```bash
flutter run -d <android_device>
```

Expected footer:
```
🤖 Platform: Android | Method: Direct Installation
```

## 🎨 Visual Differences

| Feature | iOS | Android |
|---------|-----|---------|
| Platform Icon | 🍎 | 🤖 |
| Installation Method | Universal Link | Direct Installation |
| Browser Opens | ✅ Yes (Safari/Chrome) | ❌ No |
| Stays in App | ❌ No | ✅ Yes |
| Success Message | "Safari/Chrome will open..." | "Follow system prompts..." |
| User Returns | Manual | Automatic |

## 🔄 Flow Diagram

### iOS Flow:
```
WebView → Detect iOS → JS Bridge (iOS) → Native iOS Code
    ↓
Open Universal Link → Safari/Chrome → iOS System eSIM Setup
    ↓
User Completes → User Returns to App Manually
```

### Android Flow:
```
WebView → Detect Android → JS Bridge (Android) → Native Android Code
    ↓
Direct Installation → System Dialog (in app) → Complete
    ↓
User Stays in App
```

## 💡 Key Takeaways

1. ✅ **No manual platform selection needed** - Auto-detected
2. ✅ **Unified JavaScript API** - Same code for both platforms
3. ✅ **Platform-specific native logic** - Handled in native code
4. ✅ **Clear user feedback** - Platform-specific messages
5. ✅ **No changes to esim_webview_host** - Works out of the box

## 🚀 Benefits

- **Simple Integration**: Host app doesn't need platform checks
- **Consistent API**: JavaScript developers use same methods
- **Better UX**: Users see platform-appropriate messages
- **Easy Debugging**: Console logs show detected platform
- **Visual Feedback**: Footer shows platform and method

---

**Last Updated**: February 8, 2026
**Version**: 1.0.0
