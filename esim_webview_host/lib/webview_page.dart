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
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSIM WebView v2'),
      ),
      body: FlutterEsimWebView(
        initialUrl: url,
        showAppBar: false,  // Hide SDK's AppBar to avoid double AppBar
      ),
    );
  }
}
