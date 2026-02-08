import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
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

  final List<String> _debugLines = <String>[];
  bool _showDebugOverlay = true;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;

    // Show something immediately on-screen so user can verify Dart side is alive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addDebug('FlutterEsimWebView init: url=${widget.initialUrl}');
      _addDebug('Platform: $defaultTargetPlatform');
    });

    // Capture Flutter framework errors to overlay (useful when device has no logs).
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      try {
        _addDebug('FLUTTER_ERROR: ${details.exceptionAsString()}');
      } catch (_) {
        // ignore
      }
      oldOnError?.call(details);
    };

    _setupMethodCallHandler();
  }

  @override
  void dispose() {
    // Prevent late setState from async callbacks.
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  void _addDebug(String message) {
    if (!mounted) return;
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _debugLines.add('[$ts] $message');
      if (_debugLines.length > 200) {
        _debugLines.removeRange(0, _debugLines.length - 200);
      }
    });
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onLog':
          final msg = (call.arguments as String?) ?? '';
          _addDebug('NATIVE: $msg');
          return null;
        case 'onPageStarted':
          final url = call.arguments as String;
          setState(() {
            _isLoading = true;
            _currentUrl = url;
            _errorMessage = null;
          });
          widget.onPageStarted?.call(url);
          _addDebug('Page started: $url');
          break;
          
        case 'onPageFinished':
          final url = call.arguments as String;
          setState(() {
            _isLoading = false;
            _currentUrl = url;
          });
          widget.onPageFinished?.call(url);
          _addDebug('Page finished: $url');
          break;
          
        case 'onError':
          final error = call.arguments as String;
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
          widget.onError?.call(error);
          _addDebug('ERROR: $error');
          break;
          
        case 'isSupportESim':
          _addDebug('JS Bridge called: isSupportESim');
          return await _handleIsSupportESim();
          
        case 'installEsimProfile':
          final activationCode = call.arguments as String?;
          _addDebug('JS Bridge called: installEsimProfile');
          return await _handleInstallEsimProfile(activationCode);
          
        default:
          _addDebug('Unknown method: ${call.method}');
      }
      return null;
    });
  }

  Future<String> _handleIsSupportESim() async {
    try {
      final isSupported = await _flutterEsim.isSupportESim(null);
      _addDebug('eSIM Support: $isSupported');
      return '{"success":true,"isSupported":$isSupported}';
    } catch (e) {
      _addDebug('Error checking eSIM support: $e');
      return '{"success":false,"error":"${e.toString()}","isSupported":false}';
    }
  }

  Future<String> _handleInstallEsimProfile(String? activationCode) async {
    if (activationCode == null || activationCode.isEmpty) {
      return '{"success":false,"error":"Activation code is required"}';
    }

    try {
      _addDebug('Installing eSIM profile on platform...');
      
      // Platform-specific logic
      // iOS: Open Universal Link in browser
      // Android: Install directly via CTCellularPlanProvisioning
      final result = await _flutterEsim.installEsimProfile(activationCode);
      _addDebug('Installation result: $result');
      
      if (result) {
        return '{"success":true,"message":"eSIM installation initiated successfully"}';
      } else {
        return '{"success":false,"error":"Failed to install eSIM profile"}';
      }
    } catch (e) {
      _addDebug('Error installing eSIM: $e');
      return '{"success":false,"error":"${e.toString()}"}';
    }
  }

  Future<void> _reload() async {
    if (_viewId == null) {
      _addDebug('Reload ignored: viewId is null');
      return;
    }
    try {
      await _channel.invokeMethod('reload', {'viewId': _viewId});
      _addDebug('Reload triggered');
    } catch (e) {
      _addDebug('Reload error: $e');
    }
  }

  Future<bool> _canGoBack() async {
    if (_viewId == null) {
      _addDebug('canGoBack=false (viewId is null)');
      return false;
    }
    try {
      final result = await _channel.invokeMethod('canGoBack', {'viewId': _viewId});
      return result as bool? ?? false;
    } catch (e) {
      _addDebug('CanGoBack error: $e');
      return false;
    }
  }

  Future<void> _goBack() async {
    if (_viewId == null) {
      _addDebug('goBack ignored: viewId is null');
      return;
    }
    try {
      await _channel.invokeMethod('goBack', {'viewId': _viewId});
      _addDebug('Go back triggered');
    } catch (e) {
      _addDebug('GoBack error: $e');
    }
  }

  Future<bool> _onWillPop() async {
    _addDebug('WillPopScope: onWillPop called');
    final canBack = await _canGoBack();
    if (canBack) {
      await _goBack();
      return false;
    }
    _addDebug('WillPopScope: popping route');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('eSIM WebView v2'),
          actions: [
            IconButton(
              icon: Icon(_showDebugOverlay ? Icons.bug_report : Icons.bug_report_outlined),
              onPressed: () => setState(() => _showDebugOverlay = !_showDebugOverlay),
              tooltip: 'Toggle debug overlay',
            ),
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
              child: Stack(
                children: [
                  _buildPlatformView(),
                  if (_showDebugOverlay)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: _DebugOverlay(
                        lines: _debugLines,
                        onClear: () => setState(_debugLines.clear),
                      ),
                    ),
                ],
              ),
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

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.flutter_esim/webview',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          if (!mounted) return;
          setState(() => _viewId = id);
          widget.onWebViewCreated?.call();
          _addDebug('iOS UiKitView created with ID: $id');
          _addDebug('Creation params: $creationParams');
        },
      );
    }

    return AndroidView(
      viewType: 'com.flutter_esim/webview',
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int id) {
        if (!mounted) return;
        setState(() => _viewId = id);
        widget.onWebViewCreated?.call();
        _addDebug('AndroidView created with ID: $id');
        _addDebug('Creation params: $creationParams');
      },
    );
  }
}

class _DebugOverlay extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onClear;

  const _DebugOverlay({
    required this.lines,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Debug',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  lines.isEmpty ? 'No logs yet…' : lines.reversed.take(40).join('\n'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.25,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
