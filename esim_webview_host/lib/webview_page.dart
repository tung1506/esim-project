import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

/// Simple WebView page that uses FlutterEsimWebView from the SDK
/// All WebView logic and JS Bridge are handled by flutter_esim SDK
class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterEsimWebView(
      initialUrl: url,
      onPageStarted: (url) {
        debugPrint('📄 Page started: $url');
      },
      onPageFinished: (url) {
        debugPrint('✅ Page finished: $url');
      },
      onError: (error) {
        debugPrint('❌ Error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
      onWebViewCreated: () {
        debugPrint('🌐 WebView created successfully');
      },
    );
  }
}
