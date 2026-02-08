# Flutter eSIM WebView Host

A simple Flutter app that demonstrates how to use the `flutter_esim` SDK to open remote web pages with eSIM JavaScript Bridge support.

## 🎯 Purpose

This app shows how **simple** it is to integrate eSIM functionality into any Flutter app using the `flutter_esim` SDK. All the complex WebView setup, JavaScript Bridge injection, and eSIM integration logic is handled by the SDK.

## ✨ Features

- ✅ Open remote URLs in a native WebView
- ✅ Automatic JavaScript Bridge injection
- ✅ Built-in eSIM support via `FlutterEsimBridge` API
- ✅ Page loading indicators
- ✅ Error handling
- ✅ Back navigation support
- ✅ Reload functionality

## 📦 Dependencies

```yaml
dependencies:
  flutter_esim:
    path: ../flutter_esim
```

The SDK is imported from a local path. All WebView and eSIM logic is encapsulated in the SDK.

## 🚀 Usage

### Simple Implementation (Just 3 Steps!)

#### 1. Import the SDK
```dart
import 'package:flutter_esim/flutter_esim.dart';
```

#### 2. Use the FlutterEsimWebView widget
```dart
FlutterEsimWebView(
  initialUrl: 'https://your-web-page.com',
  onPageStarted: (url) => print('Loading: $url'),
  onPageFinished: (url) => print('Loaded: $url'),
  onError: (error) => print('Error: $error'),
  onWebViewCreated: () => print('WebView ready'),
)
```

#### 3. That's it! 🎉

## 📱 Complete Example

See `lib/webview_page.dart` - **only ~25 lines of code!**

## 🌐 JavaScript API

Your web page can use these APIs (automatically injected):

```javascript
// Check eSIM support
window.FlutterEsimBridge.isSupportESim()
  .then(result => console.log('Supported:', result.isSupported));

// Install eSIM profile
window.FlutterEsimBridge.installEsimProfile(activationCode)
  .then(result => console.log('Success:', result.success));
```

## 🎓 Benefits

**Before (Without SDK):** 300+ lines of complex code
**After (With SDK):** ~25 lines - just import and use!

All complexity is handled by the SDK! 🚀

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
