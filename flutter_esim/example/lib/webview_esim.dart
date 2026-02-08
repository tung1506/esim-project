import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_esim/flutter_esim.dart';
import 'dart:convert';
import 'dart:async';

class WebViewEsimPage extends StatefulWidget {
  final String initialUrl;
  
  const WebViewEsimPage({
    Key? key, 
    this.initialUrl = 'http://localhost:3000'
  }) : super(key: key);

  @override
  State<WebViewEsimPage> createState() => _WebViewEsimPageState();
}

class _WebViewEsimPageState extends State<WebViewEsimPage> {
  final _flutterEsimPlugin = FlutterEsim();
  InAppWebViewController? _webViewController;
  StreamSubscription<dynamic>? _eventSub;
  
  double _progress = 0;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    
    // Listen to eSIM events and push to JavaScript
    _eventSub = _flutterEsimPlugin.onEvent.listen((event) {
      _pushEventToJS(event);
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _pushEventToJS(dynamic event) {
    _webViewController?.evaluateJavascript(source: '''
      if (window.onEsimEvent) {
        window.onEsimEvent(${jsonEncode(event)});
      }
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('eSIM WebView v3', style: TextStyle(fontSize: 16)),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _webViewController?.canGoBack() ?? false) {
                _webViewController?.goBack();
              }
            },
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await _webViewController?.canGoForward() ?? false) {
                _webViewController?.goForward();
              }
            },
            tooltip: 'Forward',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.initialUrl),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                mediaPlaybackRequiresUserGesture: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                
                // ⭐ JavaScript Handler: Check eSIM Support
                controller.addJavaScriptHandler(
                  handlerName: 'isSupportESim',
                  callback: (args) async {
                    try {
                      final isSupported = await _flutterEsimPlugin.isSupportESim(null);
                      return {
                        'success': true,
                        'supported': isSupported,
                      };
                    } catch (e) {
                      return {
                        'success': false,
                        'error': e.toString(),
                      };
                    }
                  },
                );
                
                // ⭐ JavaScript Handler: Install eSIM
                controller.addJavaScriptHandler(
                  handlerName: 'installEsim',
                  callback: (args) async {
                    if (args.isEmpty) {
                      return {
                        'success': false,
                        'error': 'Empty activation code',
                      };
                    }
                    
                    final activationCode = args[0] as String;
                    
                    try {
                      await _flutterEsimPlugin.installEsimProfile(activationCode);
                      return {
                        'success': true,
                        'message': 'eSIM installation started',
                      };
                    } catch (e) {
                      return {
                        'success': false,
                        'error': e.toString(),
                      };
                    }
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _currentUrl = url?.toString() ?? '';
                });
              },
              onLoadStop: (controller, url) async {
                // Inject EsimBridge object after page loads
                await controller.evaluateJavascript(source: '''
                  window.EsimBridge = {
                    isSupportESim: async function() {
                      return await window.flutter_inappwebview.callHandler('isSupportESim');
                    },
                    installEsim: async function(activationCode) {
                      return await window.flutter_inappwebview.callHandler('installEsim', activationCode);
                    }
                  };
                  
                  console.log('✅ EsimBridge injected successfully!');
                ''');
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                print('📱 WebView Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
