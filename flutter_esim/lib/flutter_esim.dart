import 'flutter_esim_platform_interface.dart';

// Export WebView widget for easy access
export 'flutter_esim_webview.dart';

class FlutterEsim {

  /// Check support eSIM.
  Future<bool> isSupportESim(List<String>? newer) async {
    return FlutterEsimPlatform.instance.isSupportESim(newer);
  }

  /// Install eSIM.
  Future<bool> installEsimProfile(String profile) async {
    return FlutterEsimPlatform.instance.installEsimProfile(profile);
  }

  /// Instructions setup eSIM.
  Future<String> instructions() async {
    return FlutterEsimPlatform.instance.instructions();
  }

  Stream<dynamic> get onEvent => FlutterEsimPlatform.instance.onEvent;
}
