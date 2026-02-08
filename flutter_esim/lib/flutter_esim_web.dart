import 'dart:async';
import 'dart:js' as js;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'flutter_esim_platform_interface.dart';

/// Web implementation of FlutterEsim
class FlutterEsimWeb extends FlutterEsimPlatform {
  FlutterEsimWeb();

  static void registerWith(Registrar registrar) {
    FlutterEsimPlatform.instance = FlutterEsimWeb();
  }

  final StreamController<dynamic> _eventController = StreamController<dynamic>.broadcast();

  @override
  Future<bool> isSupportESim(List<String>? newer) async {
    // Check if native bridge exists
    if (js.context.hasProperty('EsimNativeBridge')) {
      return await _callNativeBridgeWithCallback<bool>(
        'isEsimSupported',
        [],
        defaultValue: false,
      );
    }
    // Mock response for testing without native bridge
    return false;
  }

  @override
  Future<bool> installEsimProfile(String profile) async {
    _eventController.add({'type': 'install_start', 'profile': profile});

    if (!js.context.hasProperty('EsimNativeBridge')) {
      _eventController.add({
        'type': 'install_error',
        'error': 'Native bridge not available',
      });
      throw Exception('Native bridge not available. Please integrate EsimBridgeActivity.');
    }

    try {
      await _callNativeBridgeWithCallback<String>(
        'installEsim',
        [profile],
        defaultValue: '',
        onSuccess: (result) {
          _eventController.add({
            'type': 'install_success',
            'result': result,
          });
        },
        onError: (error) {
          _eventController.add({
            'type': 'install_error',
            'error': error,
          });
        },
      );
      return true;
    } catch (e) {
      _eventController.add({
        'type': 'install_error',
        'error': e.toString(),
      });
      rethrow;
    }
  }

  @override
  Future<String> instructions() async {
    return '''
eSIM Installer - Web Version

To use this web version:
1. This page must be loaded in a WebView within a native Android app
2. The native app must implement EsimBridgeActivity with JavaScript bridge
3. The bridge exposes eSIM installation functionality

Integration Guide:
- Add EsimBridgeActivity.kt to your Android project
- Add required permissions (WRITE_EMBEDDED_SUBSCRIPTIONS)
- Load this URL in a WebView with JavaScript enabled
- Add JavaScript interface named 'EsimNativeBridge'

Contact support for integration documentation.
''';
  }

  @override
  Stream<dynamic> get onEvent => _eventController.stream;

  /// Call native bridge with callback pattern
  Future<T> _callNativeBridgeWithCallback<T>(
    String method,
    List<dynamic> args, {
    required T defaultValue,
    Function(dynamic)? onSuccess,
    Function(dynamic)? onError,
  }) async {
    final completer = Completer<T>();

    try {
      // Create success callback
      final successCallback = js.allowInterop((result) {
        if (!completer.isCompleted) {
          onSuccess?.call(result);
          if (T == bool) {
            completer.complete(result as T? ?? defaultValue);
          } else if (T == String) {
            completer.complete(result?.toString() as T? ?? defaultValue);
          } else {
            completer.complete(result as T? ?? defaultValue);
          }
        }
      });

      // Create error callback
      final errorCallback = js.allowInterop((error) {
        if (!completer.isCompleted) {
          onError?.call(error);
          completer.completeError(error?.toString() ?? 'Unknown error');
        }
      });

      // Get native bridge
      final bridge = js.context['EsimNativeBridge'];
      
      // Call the method based on signature
      if (method == 'isEsimSupported') {
        // Single callback signature
        final methodFunc = bridge[method];
        js.context.callMethod('eval', [
          '(${js.context.callMethod('JSON.stringify', [methodFunc])})(${js.context.callMethod('JSON.stringify', [successCallback])})'
        ]);
      } else {
        // Multiple callback signature (success, error)
        bridge.callMethod(method, [
          ...args,
          successCallback,
          errorCallback,
        ]);
      }

      // Timeout after 30 seconds
      return completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.completeError('Operation timed out');
          }
          return defaultValue;
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      return defaultValue;
    }
  }
}
