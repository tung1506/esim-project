# Flutter eSIM WebView SDK - Usage Guide

## 📋 Overview

A production-ready Flutter SDK for embedding WebView with eSIM installation capabilities. Includes JavaScript bridge for checking eSIM support and installing eSIM profiles on both Android and iOS devices.

## ✨ Features

- ✅ Simple, clean API with minimal required parameters
- ✅ JavaScript bridge for eSIM operations
- ✅ Cookie and header injection support
- ✅ Lifecycle callbacks (`onWebViewCreated`, `onWebViewClosed`, `onError`)
- ✅ Optional debug console for development
- ✅ Android eSIM support (SDK 28+)
- ✅ iOS eSIM support (iOS 17.4+)
- ✅ Back navigation handling
- ✅ Loading state management

## 📦 Installation

### Option 1: From Git Repository

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_esim:
    git:
      url: https://github.com/yourusername/flutter_esim.git
      ref: main  # or specific commit SHA
```

### Option 2: Local Path (for development)

```yaml
dependencies:
  flutter_esim:
    path: ../flutter_esim
```

### Option 3: From pub.dev (if published)

```yaml
dependencies:
  flutter_esim: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class WebViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('eSIM Purchase')),
      body: FlutterEsimWebView(
        initialUrl: 'https://your-esim-provider.com/purchase',
      ),
    );
  }
}
```

### Advanced Usage with All Features

```dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class AdvancedWebViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('eSIM Purchase')),
      body: FlutterEsimWebView(
        // Required
        initialUrl: 'https://your-esim-provider.com/purchase',
        
        // Optional: Inject cookies
        initialCookies: {
          'session_id': 'abc123',
          'user_token': 'xyz789',
        },
        
        // Optional: Inject headers
        initialHeaders: {
          'Authorization': 'Bearer your-token',
          'X-Custom-Header': 'value',
        },
        
        // Optional: Enable debug console (default: false)
        debugEnabled: true,
        
        // Optional: Lifecycle callbacks
        onWebViewCreated: () {
          print('WebView created and ready');
        },
        
        onWebViewClosed: () {
          print('WebView closed/disposed');
        },
        
        onPageStarted: (url) {
          print('Page started loading: $url');
        },
        
        onPageFinished: (url) {
          print('Page finished loading: $url');
        },
        
        onError: (error) {
          print('WebView error: $error');
          // Show error dialog or handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      ),
    );
  }
}
```

## 🌐 JavaScript Bridge API

The SDK automatically injects a JavaScript bridge (`window.FlutterEsimBridge`) into your web pages.

### Available Methods

#### 1. Check eSIM Support

```javascript
// Check if device supports eSIM
window.FlutterEsimBridge.isSupportESim()
  .then(result => {
    if (result.isSupported) {
      console.log('eSIM is supported!');
      console.log('Device model:', result.deviceModel);
    } else {
      console.log('eSIM not supported:', result.message);
    }
  })
  .catch(error => {
    console.error('Error checking eSIM support:', error);
  });
```

Response format:
```javascript
{
  "isSupported": true,           // boolean
  "message": "Success",          // string
  "deviceModel": "iPhone 15 Pro" // string (device model name)
}
```

#### 2. Install eSIM Profile

```javascript
// Install eSIM with activation code
const activationCode = 'LPA:1$smdp.example.com$activation-code';

window.FlutterEsimBridge.installEsimProfile(activationCode)
  .then(result => {
    if (result.isSuccess) {
      console.log('eSIM installed successfully!');
    } else {
      console.log('Installation failed:', result.message);
    }
  })
  .catch(error => {
    console.error('Error installing eSIM:', error);
  });
```

Response format:
```javascript
{
  "isSuccess": true,              // boolean
  "message": "Installation completed" // string
}
```

### Complete Web Page Example

```html
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>eSIM Purchase</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      padding: 20px;
      max-width: 600px;
      margin: 0 auto;
    }
    button {
      background: #007AFF;
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 16px;
      cursor: pointer;
      margin: 8px 0;
      width: 100%;
    }
    button:disabled {
      background: #ccc;
      cursor: not-allowed;
    }
    .status {
      padding: 12px;
      border-radius: 8px;
      margin: 12px 0;
    }
    .success { background: #d4edda; color: #155724; }
    .error { background: #f8d7da; color: #721c24; }
    .info { background: #d1ecf1; color: #0c5460; }
  </style>
</head>
<body>
  <h1>eSIM Purchase Demo</h1>
  
  <div id="status"></div>
  
  <button id="checkSupport">Check eSIM Support</button>
  <button id="installButton" disabled>Install eSIM</button>
  
  <div id="deviceInfo" style="margin-top: 20px;"></div>

  <script>
    const statusDiv = document.getElementById('status');
    const installButton = document.getElementById('installButton');
    const deviceInfoDiv = document.getElementById('deviceInfo');
    
    // Sample activation code (replace with real code)
    const ACTIVATION_CODE = 'LPA:1$smdp.example.com$your-activation-code';
    
    function showStatus(message, type = 'info') {
      statusDiv.innerHTML = `<div class="status ${type}">${message}</div>`;
    }
    
    function showDeviceInfo(model) {
      deviceInfoDiv.innerHTML = `
        <div class="info status">
          <strong>Device Info:</strong><br>
          Model: ${model}<br>
          Platform: ${navigator.platform}<br>
          User Agent: ${navigator.userAgent}
        </div>
      `;
    }
    
    // Check eSIM support on page load
    window.addEventListener('load', async () => {
      showStatus('Checking eSIM support...', 'info');
      
      try {
        const result = await window.FlutterEsimBridge.isSupportESim();
        
        if (result.isSupported) {
          showStatus('✅ eSIM is supported on this device!', 'success');
          installButton.disabled = false;
          showDeviceInfo(result.deviceModel);
        } else {
          showStatus(`❌ ${result.message}`, 'error');
        }
      } catch (error) {
        showStatus(`Error: ${error.message}`, 'error');
      }
    });
    
    // Check support button
    document.getElementById('checkSupport').addEventListener('click', async () => {
      showStatus('Checking...', 'info');
      
      try {
        const result = await window.FlutterEsimBridge.isSupportESim();
        
        if (result.isSupported) {
          showStatus(`✅ Supported - ${result.deviceModel}`, 'success');
          installButton.disabled = false;
          showDeviceInfo(result.deviceModel);
        } else {
          showStatus(`❌ ${result.message}`, 'error');
          installButton.disabled = true;
        }
      } catch (error) {
        showStatus(`Error: ${error.message}`, 'error');
      }
    });
    
    // Install eSIM button
    installButton.addEventListener('click', async () => {
      showStatus('Installing eSIM profile...', 'info');
      installButton.disabled = true;
      
      try {
        const result = await window.FlutterEsimBridge.installEsimProfile(ACTIVATION_CODE);
        
        if (result.isSuccess) {
          showStatus('✅ eSIM installed successfully!', 'success');
        } else {
          showStatus(`❌ Installation failed: ${result.message}`, 'error');
          installButton.disabled = false;
        }
      } catch (error) {
        showStatus(`Error: ${error.message}`, 'error');
        installButton.disabled = false;
      }
    });
  </script>
</body>
</html>
```

## 📱 Platform Requirements

### Android
- Minimum SDK: **28 (Android 9.0 / Pie)**
- Device must have eSIM hardware support
- `READ_PHONE_STATE` permission required (automatically requested)

### iOS
- Minimum version: **iOS 17.4**
- Device must be in the supported model list (iPhone XS and newer)
- CoreTelephony framework required (automatically linked)

### Supported iOS Models
- iPhone XS, XS Max, XR (2018+)
- iPhone 11, 11 Pro, 11 Pro Max
- iPhone 12 series
- iPhone 13 series
- iPhone 14 series
- iPhone 15 series
- iPad Pro (2018+)
- iPad Air (2019+)
- iPad (2019+)
- iPad mini (2019+)

## 🔧 Configuration

### Android Configuration

No additional configuration required. The SDK handles permissions automatically.

If you need to manually configure permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- eSIM permissions (optional - SDK requests these automatically) -->
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

### iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs to access eSIM installation services.</string>
```

## 🎨 UI Customization

### Debug Console

The debug console is **disabled by default** in production. Enable it during development:

```dart
FlutterEsimWebView(
  initialUrl: 'https://example.com',
  debugEnabled: true,  // Shows debug console overlay
)
```

The debug console shows:
- Page navigation events
- JavaScript bridge calls
- eSIM check results
- Installation status
- Error messages
- Timestamps for all events

### Loading Indicator

The SDK includes a built-in loading indicator. To customize it, fork the SDK and modify the `_buildLoadingIndicator()` method in `flutter_esim_webview.dart`.

## 🔒 Security Best Practices

### 1. HTTPS Only
Always use HTTPS URLs in production:

```dart
FlutterEsimWebView(
  initialUrl: 'https://secure-esim-provider.com',  // ✅ Good
  // initialUrl: 'http://insecure-site.com',       // ❌ Bad
)
```

### 2. Validate Activation Codes
Always validate activation codes on your backend before sending to the app:

```javascript
// Server-side validation example
function validateActivationCode(code) {
  // Check format: LPA:1$smdp.domain.com$code
  const lpaPattern = /^LPA:1\$.+\$.+$/;
  return lpaPattern.test(code);
}
```

### 3. Handle Sensitive Data
Don't log sensitive information in production:

```dart
FlutterEsimWebView(
  initialUrl: url,
  debugEnabled: kDebugMode,  // Only enable in debug builds
)
```

### 4. Cookie Security
Use secure cookies when possible:

```dart
FlutterEsimWebView(
  initialUrl: url,
  initialCookies: {
    'session': 'value; Secure; HttpOnly; SameSite=Strict',
  },
)
```

## 🐛 Debugging

### Enable Debug Console

```dart
FlutterEsimWebView(
  initialUrl: 'https://example.com',
  debugEnabled: true,
)
```

### Check Platform Logs

**Android:**
```bash
flutter logs | grep -i esim
# or
adb logcat | grep -i esim
```

**iOS:**
```bash
flutter logs | grep -i esim
# or
# Open Console.app and filter by "esim"
```

### Common Issues

#### 1. "eSIM not supported" on supported device

**Solution:** Check platform requirements
- Android: SDK 28+ required
- iOS: Version 17.4+ required

```dart
// Add callback to check detailed error
FlutterEsimWebView(
  initialUrl: url,
  onError: (error) {
    print('Error details: $error');
  },
)
```

#### 2. JavaScript bridge not available

**Solution:** Wait for page to load completely

```javascript
// Wait for bridge to be ready
window.addEventListener('load', () => {
  if (window.FlutterEsimBridge) {
    // Bridge is ready
  } else {
    console.error('FlutterEsimBridge not found');
  }
});
```

#### 3. Installation fails silently

**Solution:** Check activation code format

```javascript
// Correct format
const code = 'LPA:1$smdp.example.com$activation-code';

// Incorrect formats
// const code = 'activation-code';  // ❌ Missing LPA prefix
// const code = 'LPA:activation';   // ❌ Wrong format
```

## 📊 Testing

### Test on Real Devices

**Android:**
```bash
cd esim_webview_host
flutter run -d <android-device-id>
```

**iOS:**
```bash
cd esim_webview_host
flutter run -d <ios-device-id>
```

### Test eSIM Support Check

```dart
// In your test file
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final plugin = FlutterEsim();
  final result = await plugin.isSupportESim();
  
  print('eSIM supported: ${result['isSupported']}');
  print('Message: ${result['message']}');
  print('Device: ${result['deviceModel']}');
}
```

### Integration Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_esim/flutter_esim.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WebView loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterEsimWebView(
            initialUrl: 'https://example.com',
            onPageFinished: (url) {
              print('Page loaded: $url');
            },
          ),
        ),
      ),
    );

    // Wait for WebView to load
    await tester.pumpAndSettle(Duration(seconds: 3));

    // Verify WebView is present
    expect(find.byType(FlutterEsimWebView), findsOneWidget);
  });
}
```

## 📚 API Reference

### FlutterEsimWebView Constructor

```dart
FlutterEsimWebView({
  Key? key,
  required String initialUrl,              // Required: Initial URL to load
  Map<String, String>? initialCookies,     // Optional: Cookies to inject
  Map<String, String>? initialHeaders,     // Optional: Headers to inject
  ValueChanged<String>? onPageStarted,     // Optional: Called when page starts loading
  ValueChanged<String>? onPageFinished,    // Optional: Called when page finishes loading
  VoidCallback? onWebViewCreated,          // Optional: Called when WebView is created
  VoidCallback? onWebViewClosed,           // Optional: Called when WebView is disposed
  ValueChanged<String>? onError,           // Optional: Called on error
  bool debugEnabled = false,               // Optional: Enable debug console (default: false)
})
```

### JavaScript Bridge Methods

#### `window.FlutterEsimBridge.isSupportESim()`

Returns: `Promise<{isSupported: boolean, message: string, deviceModel: string}>`

#### `window.FlutterEsimBridge.installEsimProfile(activationCode: string)`

Parameters:
- `activationCode`: String - LPA format activation code

Returns: `Promise<{isSuccess: boolean, message: string}>`

## 📝 Migration Guide

### From v1.x to v2.x

```dart
// OLD (v1.x)
FlutterEsimWebView(
  url: 'https://example.com',  // ❌ Deprecated
  showAppBar: true,            // ❌ Removed
)

// NEW (v2.x)
FlutterEsimWebView(
  initialUrl: 'https://example.com',  // ✅ New parameter name
  // showAppBar removed - manage AppBar in parent Scaffold
)
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

This SDK is licensed under the MIT License. See LICENSE file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_esim/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_esim/discussions)
- **Email**: support@yourcompany.com

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

Made with ❤️ by Your Team
