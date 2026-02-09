# Flutter eSIM WebView SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Production-ready Flutter SDK for embedding WebView with eSIM installation capabilities.**

Includes JavaScript bridge for checking eSIM support and installing eSIM profiles on both Android and iOS devices.

## ✨ Features

- ✅ **Simple API** - Only `initialUrl` required
- ✅ **JavaScript Bridge** - Seamless communication between web and native
- ✅ **Cookie & Header Injection** - Easy authentication integration
- ✅ **Lifecycle Callbacks** - Track WebView creation, closure, and errors
- ✅ **Debug Console** - Optional debug overlay for development
- ✅ **Android Support** - SDK 28+ (Android 9.0+)
- ✅ **iOS Support** - iOS 17.4+
- ✅ **Production Ready** - Clean, documented, senior-level code

## 📦 Installation

### Option 1: From Git Repository

```yaml
dependencies:
  flutter_esim:
    git:
      url: https://github.com/yourusername/flutter_esim.git
      ref: main
```

### Option 2: Local Path

```yaml
dependencies:
  flutter_esim:
    path: ../flutter_esim
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Import the SDK

```dart
import 'package:flutter_esim/flutter_esim.dart';
```

### 2. Use in Your App

```dart
class MyWebViewPage extends StatelessWidget {
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

### 3. Add JavaScript Bridge in Your Web Page

```javascript
// Check eSIM support
const result = await window.FlutterEsimBridge.isSupportESim();
console.log('Supported:', result.isSupported);

// Install eSIM
const activationCode = 'LPA:1$smdp.example.com$code';
const installResult = await window.FlutterEsimBridge.installEsimProfile(activationCode);
console.log('Success:', installResult.isSuccess);
```

## 📚 Documentation

- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - Complete API reference and usage guide
- **[INTEGRATION_EXAMPLE.md](INTEGRATION_EXAMPLE.md)** - 7 real-world integration examples
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Testing instructions

## 📱 Platform Requirements

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| Android  | SDK 28 (Android 9.0+) | eSIM hardware required |
| iOS      | 17.4+ | iPhone XS and newer |

## 🎯 Advanced Usage

### With Authentication

```dart
FlutterEsimWebView(
  initialUrl: 'https://example.com',
  initialCookies: {'session': 'token123'},
  initialHeaders: {'Authorization': 'Bearer token'},
  onWebViewCreated: () => print('Ready'),
  onWebViewClosed: () => print('Closed'),
  onError: (error) => print('Error: $error'),
  debugEnabled: true, // Show debug console
)
```

### JavaScript Bridge API

```javascript
// Check support
window.FlutterEsimBridge.isSupportESim()
  .then(result => {
    // result: {isSupported: bool, message: string, deviceModel: string}
  });

// Install eSIM
window.FlutterEsimBridge.installEsimProfile(activationCode)
  .then(result => {
    // result: {isSuccess: bool, message: string}
  });
```

## 📖 Complete Examples

See [INTEGRATION_EXAMPLE.md](INTEGRATION_EXAMPLE.md) for:

1. ✅ Basic eSIM purchase flow
2. ✅ With authentication (cookies & headers)
3. ✅ With loading progress and error handling
4. ✅ Check eSIM support before opening WebView
5. ✅ Production-ready with analytics
6. ✅ Main app integration
7. ✅ Backend integration (Node.js example)

## 🔧 API Reference

### FlutterEsimWebView Constructor

```dart
FlutterEsimWebView({
  required String initialUrl,              // URL to load
  Map<String, String>? initialCookies,     // Optional cookies
  Map<String, String>? initialHeaders,     // Optional headers
  ValueChanged<String>? onPageStarted,     // Page load started
  ValueChanged<String>? onPageFinished,    // Page load finished
  VoidCallback? onWebViewCreated,          // WebView created
  VoidCallback? onWebViewClosed,           // WebView disposed
  ValueChanged<String>? onError,           // Error occurred
  bool debugEnabled = false,               // Show debug console
})
```

## 🐛 Debug Mode

Enable debug console in development:

```dart
FlutterEsimWebView(
  initialUrl: url,
  debugEnabled: true,  // Shows debug overlay with logs
)
```

## 🔒 Security Best Practices

1. ✅ Always use HTTPS in production
2. ✅ Validate activation codes on backend
3. ✅ Use secure cookies (HttpOnly, Secure, SameSite)
4. ✅ Enable debug mode only in development (`kDebugMode`)
5. ✅ Don't log sensitive data in production

## 🧪 Testing

Test on real devices (emulators don't support eSIM):

```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_esim/issues)
- **Documentation**: See [USAGE_GUIDE.md](USAGE_GUIDE.md)
- **Examples**: See [INTEGRATION_EXAMPLE.md](INTEGRATION_EXAMPLE.md)

---

## 📝 Migration from v1.x to v2.x

### Breaking Changes

#### 1. Parameter Names Changed

```dart
// OLD (v1.x)
FlutterEsimWebView(
  url: 'https://example.com',     // ❌ Deprecated
  showAppBar: true,                // ❌ Removed
)

// NEW (v2.x)
FlutterEsimWebView(
  initialUrl: 'https://example.com',  // ✅ Use this instead
  // Manage AppBar in parent Scaffold
)
```

#### 2. New Features Added

```dart
// NEW in v2.x
FlutterEsimWebView(
  initialUrl: url,
  
  // NEW: Cookie and header injection
  initialCookies: {'session': 'token'},
  initialHeaders: {'Authorization': 'Bearer token'},
  
  // NEW: Lifecycle callbacks
  onWebViewCreated: () => print('Created'),
  onWebViewClosed: () => print('Closed'),
  
  // NEW: Debug control
  debugEnabled: true,
)
```

#### 3. Method Naming (Internal - No Action Required)

Internal methods have been renamed for clarity, but this doesn't affect public API:
- `_handleIsSupportESim` → `_handleCheckESimSupport`
- `_handleInstallEsimProfile` → `_handleInstallESimProfile`
- `_addDebug` → `_logDebug`

### Platform Requirements Updated

- **Android**: Now requires SDK 28+ (was SDK 22+)
- **iOS**: Now requires iOS 17.4+ (was iOS 13.0+)

### Testing After Migration

1. Update your `pubspec.yaml` dependency
2. Run `flutter pub get`
3. Replace `url` parameter with `initialUrl`
4. Remove `showAppBar` parameter (manage AppBar in your Scaffold)
5. Test on real devices with updated platform versions

---

## 🔧 Legacy API (v1.x)

If you still need the old API for direct eSIM operations without WebView:

```dart
import 'package:flutter_esim/flutter_esim.dart';

// Check eSIM support (v1.x style)
final plugin = FlutterEsim();
final result = await plugin.isSupportESim();
print('Supported: ${result['isSupported']}');

// Install eSIM profile (v1.x style)
final installResult = await plugin.installEsimProfile(activationCode);
print('Success: ${installResult['isSuccess']}');
```

---

Made with ❤️ by Flutter eSIM Team

#### Compatibility Check:

You can integrate eSIM functionality into your iOS app by following the steps below. Please note that the process involves requesting entitlement approval from Apple.
https://developer.apple.com//contact/request/esim-access-entitlement

#### Steps:

##### Step 1: Request eSIM Entitlement

Using your developer account, submit a request for the eSIM entitlement through the Apple Developer portal.

##### Step 2: Approval Process

Apple will review and approve the entitlement request. You can check the status of the approval in your app's profile settings.

##### Step 3: Download Profiles

Download the App Development and Distribution profiles. Ensure that the eSIM entitlement is selected as part of Step #2 in the profile settings.

##### Step 4: Update Info.plist

Update your Info.plist file with the following keys and values:

```xml
<key>CarrierDescriptors</key>
<array>
  <dict>
    <key>GID1</key>
    <string>***</string>
    <key>GID2</key>
    <string>***</string>
    <key>MCC</key> <!-- Country Code -->
    <string>***</string>
    <key>MNC</key> <!-- Network Code -->
    <string>***</string>
  </dict>
</array>
```

Note: You can obtain GID1, GID2, MCC, and MNC information for eSIM compatibility from various sources:

* Mobile Network Operators: Contact your mobile network operator for specific eSIM card details.
* Online eSIM Providers: Many providers such as Truphone, Twilio, and Unlocator publish this information on their websites.
* Device Manufacturers: Some manufacturers like Apple and Samsung provide details on their websites or in user manuals.
* eSIM Databases: Websites like esimdb.com offer information on eSIM cards and associated codes.
It's crucial to acknowledge that eSIM compatibility may vary based on the mobile network operator and device. Therefore, always refer to the specific provider or manufacturer for accurate and up-to-date information.

For more details, refer to the <a href="https://pub.dev/documentation/flutter_esim/latest">API Reference</a> section.

## Example
Check out the <a href="https://github.com/hiennguyen92/flutter_esim/tree/main/example">example</a> directory for a simple Flutter app demonstrating the usage of this plugin.

## Contributing
Feel free to contribute to this project!

## License
This project is licensed under the <a href="https://github.com/hiennguyen92/flutter_esim/blob/main/LICENSE">MIT License</a>.

---

## 🌐 WebView Integration (NEW)

### FlutterEsimWebView Widget

The plugin now includes a **complete WebView solution** with built-in JavaScript Bridge for seamless eSIM integration:

```dart
import 'package:flutter_esim/flutter_esim.dart';

class MyEsimPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterEsimWebView(
      initialUrl: 'https://your-esim-provider.com/purchase',
      onPageStarted: (url) => print('Started: $url'),
      onPageFinished: (url) => print('Finished: $url'),
      onError: (error) => print('Error: $error'),
    );
  }
}
```

### Platform-Specific Installation Methods

#### iOS: Universal Link (NEW) 🍎
- Opens Safari/Chrome with Universal Link
- URL: `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata={code}`
- Native iOS eSIM setup experience
- **No callback** (user returns to app manually)

#### Android: Direct Installation 🤖
- System dialog appears within app
- Direct installation via Android API
- User stays in app throughout process

### JavaScript Bridge API

Your HTML page can use this unified API on both platforms:

```javascript
// Check eSIM support
const result = await FlutterEsimBridge.isSupportESim();
// iOS: Always returns { success: true, supported: true }
// Android: Checks device capability

// Install eSIM profile
const activationCode = "LPA:1$sm-dp.example.com$activation-code";
const result = await FlutterEsimBridge.installEsimProfile(activationCode);
// iOS: Opens Universal Link → Safari → iOS Settings
// Android: Direct installation → System dialog (in-app)
```

### Platform Detection

The HTML page automatically detects the platform and adapts:

```javascript
// Automatic detection via User Agent
- iOS: Shows "🍎 Platform: iOS | Method: Universal Link"
- Android: Shows "🤖 Platform: Android | Method: Direct Installation"
```

### Documentation

For complete implementation details, see:

- **[SUMMARY.md](SUMMARY.md)** - Complete overview of Universal Link implementation
- **[IOS_UNIVERSAL_LINK_IMPLEMENTATION.md](IOS_UNIVERSAL_LINK_IMPLEMENTATION.md)** - iOS technical details
- **[PLATFORM_DETECTION.md](PLATFORM_DETECTION.md)** - Platform detection guide  
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Testing instructions for both platforms
- **[ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md)** - Visual architecture diagrams

### Sample HTML Page

See `example/web/esim_purchase.html` for a complete working example with:
- ✅ Modern responsive UI
- ✅ Auto platform detection
- ✅ Real-time console logs
- ✅ Platform-specific user feedback
- ✅ Error handling

### No Host App Changes Required

The `FlutterEsimWebView` widget handles everything:
- ✅ Platform detection
- ✅ WebView creation (WKWebView for iOS, WebView for Android)
- ✅ JavaScript Bridge injection
- ✅ Platform-specific eSIM installation flow

Just drop in the widget and it works! 🚀

---

**Made with ❤️ for seamless eSIM integration**

**Updated**: February 8, 2026 | **Version**: 1.0.0+webview