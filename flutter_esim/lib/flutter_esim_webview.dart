import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'flutter_esim.dart';

/// A WebView widget that automatically integrates eSIM functionality
/// via JavaScript bridge for remote web pages.
class FlutterEsimWebView extends StatefulWidget {
  /// The initial URL to load in the WebView
  final String initialUrl;
  
  /// Optional callback when page starts loading
  final ValueChanged<String>? onPageStarted;
  
  /// Optional callback when page finishes loading
  final ValueChanged<String>? onPageFinished;
  
  /// Optional callback when an error occurs
  final ValueChanged<String>? onError;
  
  /// Optional callback when WebView is created
  final VoidCallback? onWebViewCreated;

  const FlutterEsimWebView({
    super.key,
    required this.initialUrl,
    this.onPageStarted,
    this.onPageFinished,
    this.onError,
    this.onWebViewCreated,
  });

  @override
  State<FlutterEsimWebView> createState() => _FlutterEsimWebViewState();
}

class _FlutterEsimWebViewState extends State<FlutterEsimWebView> {
  static const _channel = MethodChannel('com.flutter_esim/webview');
  final _flutterEsim = FlutterEsim();
  
  bool _isLoading = true;
  String _currentUrl = '';
  String? _errorMessage;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPageStarted':
          final url = call.arguments as String;
          setState(() {
            _isLoading = true;
            _currentUrl = url;
            _errorMessage = null;
          });
          widget.onPageStarted?.call(url);
          debugPrint('📄 Page started: $url');
          break;
          
        case 'onPageFinished':
          final url = call.arguments as String;
          setState(() {
            _isLoading = false;
            _currentUrl = url;
          });
          widget.onPageFinished?.call(url);
          debugPrint('✅ Page finished: $url');
          break;
          
        case 'onError':
          final error = call.arguments as String;
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
          widget.onError?.call(error);
          debugPrint('❌ Error: $error');
          break;
          
        case 'isSupportESim':
          debugPrint('🔍 JS Bridge called: isSupportESim');
          return await _handleIsSupportESim();
          
        case 'installEsimProfile':
          final activationCode = call.arguments as String?;
          debugPrint('📲 JS Bridge called: installEsimProfile');
          return await _handleInstallEsimProfile(activationCode);
          
        default:
          debugPrint('⚠️ Unknown method: ${call.method}');
      }
      return null;
    });
  }

  Future<String> _handleIsSupportESim() async {
    try {
      final isSupported = await _flutterEsim.isSupportESim(null);
      debugPrint('✅ eSIM Support: $isSupported');
      return '{"success":true,"isSupported":$isSupported}';
    } catch (e) {
      debugPrint('❌ Error checking eSIM support: $e');
      return '{"success":false,"error":"${e.toString()}","isSupported":false}';
    }
  }

  Future<String> _handleInstallEsimProfile(String? activationCode) async {
    if (activationCode == null || activationCode.isEmpty) {
      return '{"success":false,"error":"Activation code is required"}';
    }

    try {
      debugPrint('📲 Installing eSIM profile on platform...');
      
      // Platform-specific logic
      // iOS: Open Universal Link in browser
      // Android: Install directly via CTCellularPlanProvisioning
      final result = await _flutterEsim.installEsimProfile(activationCode);
      debugPrint('✅ Installation result: $result');
      
      if (result) {
        return '{"success":true,"message":"eSIM installation initiated successfully"}';
      } else {
        return '{"success":false,"error":"Failed to install eSIM profile"}';
      }
    } catch (e) {
      debugPrint('❌ Error installing eSIM: $e');
      return '{"success":false,"error":"${e.toString()}"}';
    }
  }

  Future<void> _reload() async {
    if (_viewId == null) return;
    try {
      await _channel.invokeMethod('reload', {'viewId': _viewId});
      debugPrint('🔄 Reload triggered');
    } catch (e) {
      debugPrint('❌ Reload error: $e');
    }
  }

  Future<bool> _canGoBack() async {
    if (_viewId == null) return false;
    try {
      final result = await _channel.invokeMethod('canGoBack', {'viewId': _viewId});
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('❌ CanGoBack error: $e');
      return false;
    }
  }

  Future<void> _goBack() async {
    if (_viewId == null) return;
    try {
      await _channel.invokeMethod('goBack', {'viewId': _viewId});
      debugPrint('⬅️ Go back triggered');
    } catch (e) {
      debugPrint('❌ GoBack error: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (await _canGoBack()) {
      await _goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('eSIM WebView'),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
              tooltip: 'Reload',
            ),
          ],
        ),
        body: Column(
          children: [
            // URL bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.red[100],
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _errorMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            
            // WebView
            Expanded(
              child: _buildPlatformView(),
            ),
          ],
        ),
      ),
    );
  }

  // Build platform-specific view
  Widget _buildPlatformView() {
    final creationParams = {
      'url': widget.initialUrl,
    };

    // iOS uses UiKitView with Hybrid Composition
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.flutter_esim/webview',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          setState(() => _viewId = id);
          widget.onWebViewCreated?.call();
          debugPrint('� iOS WebView created with ID: $id');
        },
        // Use Hybrid Composition for better compatibility
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      );
    }
    
    // Android uses AndroidView
    return AndroidView(
      viewType: 'com.flutter_esim/webview',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int id) {
        setState(() => _viewId = id);
        widget.onWebViewCreated?.call();
        debugPrint('🤖 Android WebView created with ID: $id');
      },
    );
  }
}
