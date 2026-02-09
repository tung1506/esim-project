import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'flutter_esim.dart';

/// A production-ready WebView widget with eSIM functionality via JavaScript bridge.
/// 
/// This widget provides a clean API for displaying web content with eSIM integration.
/// The host application should provide its own AppBar and navigation structure.
/// 
/// Example:
/// ```dart
/// FlutterEsimWebView(
///   initialUrl: 'https://example.com',
///   debugEnabled: true,
///   onWebViewCreated: () => print('WebView ready'),
///   onWebViewClosed: () => print('WebView closed'),
///   onError: (error) => print('Error: $error'),
/// )
/// ```
class FlutterEsimWebView extends StatefulWidget {
  /// The initial URL to load in the WebView (required)
  final String initialUrl;

  /// Optional cookies to inject into the WebView session
  /// Format: Map of cookie name to cookie value
  final Map<String, String>? initialCookies;

  /// Optional HTTP headers to add to the initial request
  final Map<String, String>? initialHeaders;
  
  /// Optional callback when page starts loading
  final ValueChanged<String>? onPageStarted;
  
  /// Optional callback when page finishes loading
  final ValueChanged<String>? onPageFinished;
  
  /// Optional callback when WebView is created and ready
  final VoidCallback? onWebViewCreated;

  /// Optional callback when WebView is closed/disposed
  final VoidCallback? onWebViewClosed;
  
  /// Optional callback when an error occurs
  /// Receives error message with details
  final ValueChanged<String>? onError;

  /// Enable debug overlay for development (defaults to false)
  /// When enabled, shows a debug console at the bottom of the WebView
  final bool debugEnabled;

  const FlutterEsimWebView({
    super.key,
    required this.initialUrl,
    this.initialCookies,
    this.initialHeaders,
    this.debugEnabled = false,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebViewCreated,
    this.onWebViewClosed,
    this.onError,
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

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logDebug('WebView initializing: ${widget.initialUrl}');
      _logDebug('Platform: $defaultTargetPlatform');
      _logDebug('Debug mode: ${widget.debugEnabled}');
    });

    _setupMethodCallHandler();
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    widget.onWebViewClosed?.call();
    super.dispose();
  }

  /// Log debug messages (only shown if debugEnabled)
  void _logDebug(String message) {
    if (!widget.debugEnabled || !mounted) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    setState(() {
      _debugLines.add('[$timestamp] $message');
      // Keep only last 100 lines for performance
      if (_debugLines.length > 100) {
        _debugLines.removeRange(0, _debugLines.length - 100);
      }
    });
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onLog':
          final msg = (call.arguments as String?) ?? '';
          _logDebug('Native: $msg');
          return null;

        case 'onPageStarted':
          final url = call.arguments as String;
          setState(() {
            _isLoading = true;
            _currentUrl = url;
            _errorMessage = null;
          });
          widget.onPageStarted?.call(url);
          _logDebug('Page loading: $url');
          break;

        case 'onPageFinished':
          final url = call.arguments as String;
          setState(() {
            _isLoading = false;
            _currentUrl = url;
          });
          widget.onPageFinished?.call(url);
          _logDebug('Page loaded: $url');
          break;

        case 'onError':
          final error = call.arguments as String;
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
          widget.onError?.call(error);
          _logDebug('Error: $error');
          break;

        case 'isSupportESim':
          _logDebug('Bridge call: isSupportESim');
          return await _handleCheckESimSupport();

        case 'installEsimProfile':
          final activationCode = call.arguments as String?;
          _logDebug('Bridge call: installEsimProfile');
          return await _handleInstallESimProfile(activationCode);

        default:
          _logDebug('Unknown method: ${call.method}');
      }
      return null;
    });
  }

  Future<String> _handleCheckESimSupport() async {
    try {
      final isSupported = await _flutterEsim.isSupportESim(null);
      _logDebug('eSIM support check: $isSupported');
      return '{"success":true,"isSupported":$isSupported}';
    } catch (e) {
      _logDebug('eSIM support check failed: $e');
      return '{"success":false,"error":"${e.toString()}","isSupported":false}';
    }
  }

  Future<String> _handleInstallESimProfile(String? activationCode) async {
    if (activationCode == null || activationCode.isEmpty) {
      _logDebug('Install failed: no activation code');
      return '{"success":false,"error":"Activation code is required"}';
    }

    try {
      _logDebug('Installing eSIM profile...');
      final result = await _flutterEsim.installEsimProfile(activationCode);
      _logDebug('Installation result: $result');
      
      if (result) {
        return '{"success":true,"message":"eSIM installation initiated"}';
      } else {
        return '{"success":false,"error":"Installation failed"}';
      }
    } catch (e) {
      _logDebug('Installation error: $e');
      return '{"success":false,"error":"${e.toString()}"}';
    }
  }

  Future<void> _reload() async {
    if (_viewId == null) {
      _logDebug('Reload skipped: view not ready');
      return;
    }
    try {
      await _channel.invokeMethod('reload', {'viewId': _viewId});
      _logDebug('Page reloaded');
    } catch (e) {
      _logDebug('Reload error: $e');
    }
  }

  Future<bool> _canGoBack() async {
    if (_viewId == null) return false;
    try {
      final result = await _channel.invokeMethod('canGoBack', {'viewId': _viewId});
      return result as bool? ?? false;
    } catch (e) {
      _logDebug('Navigation check error: $e');
      return false;
    }
  }

  Future<void> _goBack() async {
    if (_viewId == null) {
      _logDebug('Back navigation skipped: view not ready');
      return;
    }
    try {
      await _channel.invokeMethod('goBack', {'viewId': _viewId});
      _logDebug('Navigated back');
    } catch (e) {
      _logDebug('Back navigation error: $e');
    }
  }

  Future<bool> _handleBackNavigation() async {
    final canNavigateBack = await _canGoBack();
    if (canNavigateBack) {
      await _goBack();
      return false; // Don't pop route
    }
    return true; // Pop route
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Column(
        children: [
          // Clean URL bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.debugEnabled)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _reload,
                    tooltip: 'Reload',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),

          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _errorMessage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                _buildPlatformView(),
                if (widget.debugEnabled && _debugLines.isNotEmpty)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: _DebugConsole(
                      lines: _debugLines,
                      onClear: () => setState(_debugLines.clear),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build platform-specific WebView
  Widget _buildPlatformView() {
    final creationParams = <String, dynamic>{
      'url': widget.initialUrl,
      if (widget.initialCookies != null && widget.initialCookies!.isNotEmpty)
        'cookies': widget.initialCookies,
      if (widget.initialHeaders != null && widget.initialHeaders!.isNotEmpty)
        'headers': widget.initialHeaders,
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
          _logDebug('iOS WebView created (ID: $id)');
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
        _logDebug('Android WebView created (ID: $id)');
      },
    );
  }
}

/// Clean debug console overlay (no icons, minimalist design)
class _DebugConsole extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onClear;

  const _DebugConsole({
    required this.lines,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Debug Console',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  lines.isEmpty ? 'No logs yet' : lines.join('\n'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.3,
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
