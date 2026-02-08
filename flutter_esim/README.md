# Flutter eSIM Plugin

[![pub package](https://img.shields.io/pub/v/flutter_esim.svg)](https://pub.dev/packages/flutter_esim)
[![GitHub stars](https://img.shields.io/github/stars/hiennguyen92/flutter_esim.svg?style=social)](https://github.com/hiennguyen92/flutter_esim/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/hiennguyen92/flutter_esim.svg?style=social)](https://github.com/hiennguyen92/flutter_esim/network)
[![GitHub issues](https://img.shields.io/github/issues/hiennguyen92/flutter_esim.svg)](https://github.com/hiennguyen92/flutter_esim/issues)
[![GitHub license](https://img.shields.io/github/license/hiennguyen92/flutter_esim.svg)](https://github.com/hiennguyen92/flutter_esim/blob/master/LICENSE)

A Flutter plugin for checking eSIM support and installing eSIM profiles directly within your app.

## Table of Contents

- [Getting Started](#getting-started)
- [Installation](#installation)
- [Usage](#usage)
- [Example](#example)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)
- [WebView Integration](#webview-integration)

## Getting Started

To use this plugin, add `flutter_esim` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  flutter_esim: ^latest_version
```

Then, run the command:

```
flutter pub get
```

## Installation
Make sure to follow the platform-specific setup for your project:

Android: No additional setup required.</br>
iOS: No additional setup required.

## Usage
Import the library in your Dart file:
```
import 'package:flutter_esim/flutter_esim.dart';
```

Now you can use the FlutterEsim class to check eSIM support and install eSIM profiles.

```
// Check if the device supports eSIM
// Does not require requesting entitlement approval from Apple (Manual checking)
bool isEsimSupported = await FlutterEsim.isEsimSupported();

// Check if the device supports eSIM
// Does not require requesting entitlement approval from Apple (Manual checking)
// You can add some devices that are not yet on the market that you want to check
List<String> newer = ['iPhone18,4', 'iPhone19,4']
bool isEsimSupported = await FlutterEsim.isEsimSupported(newer);

// Install an eSIM profile
// Require requesting entitlement approval from Apple
bool installedSuccessfully = await FlutterEsim.installEsimProfile(profileData);

// A piece of text containing simple steps for setting up eSIM.
bool textInstructions = await FlutterEsim.instructions();

```

### eSIM Integration Guidelines for iOS

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