import Flutter
import UIKit
import WebKit

class FlutterEsimWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var methodChannel: FlutterMethodChannel
    
    init(messenger: FlutterBinaryMessenger, methodChannel: FlutterMethodChannel) {
        self.messenger = messenger
        self.methodChannel = methodChannel
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FlutterEsimWebView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger,
            methodChannel: methodChannel
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class FlutterEsimWebView: NSObject, FlutterPlatformView, WKNavigationDelegate, WKScriptMessageHandler {
    private var _webView: WKWebView
    private var methodChannel: FlutterMethodChannel
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger,
        methodChannel: FlutterMethodChannel
    ) {
        self.methodChannel = methodChannel
        
        // Configure WKWebView
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        // Enable JavaScript
        configuration.preferences.javaScriptEnabled = true
        
        // Allow inline media playback
        configuration.allowsInlineMediaPlayback = true
        
        // Allow picture in picture
        configuration.allowsPictureInPictureMediaPlayback = true
        
        // Media types requiring user action
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        _webView = WKWebView(frame: frame, configuration: configuration)
        
        super.init()
        
        // Set delegates
        _webView.navigationDelegate = self
        
        // Enable scrolling
        _webView.scrollView.isScrollEnabled = true
        
        // Set background color
        _webView.isOpaque = false
        _webView.backgroundColor = UIColor.white
        
        // Allow magnification
        _webView.allowsMagnification = false
        
        // Add script message handlers for JS Bridge
        userContentController.add(self, name: "flutterEsimBridge")
        
        // Parse arguments and load URL
        if let args = args as? [String: Any],
           let url = args["url"] as? String,
           let urlObj = URL(string: url) {
            let request = URLRequest(url: urlObj)
            _webView.load(request)
        }
    }
    
    func view() -> UIView {
        return _webView
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            methodChannel.invokeMethod("onPageStarted", arguments: url)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            // Inject JS Bridge after page loads
            injectJsBridge(webView: webView)
            methodChannel.invokeMethod("onPageFinished", arguments: url)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let errorMessage = "Error: \(error.localizedDescription)"
        methodChannel.invokeMethod("onError", arguments: errorMessage)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let errorMessage = "Error: \(error.localizedDescription)"
        methodChannel.invokeMethod("onError", arguments: errorMessage)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "flutterEsimBridge" else { return }
        
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else {
            return
        }
        
        let args = body["args"]
        
        switch method {
        case "installEsimProfile":
            if let activationCode = args as? String {
                handleInstallEsimProfile(activationCode: activationCode, webView: message.webView)
            }
        case "openUniversalLink":
            if let activationCode = args as? String {
                handleInstallEsimProfile(activationCode: activationCode, webView: message.webView)
            }
        default:
            print("Unknown method: \(method)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func injectJsBridge(webView: WKWebView) {
        let jsCode = """
        (function() {
            console.log('Injecting iOS FlutterEsimBridge...');
            
            window.FlutterEsimBridge = {
                isSupportESim: function() {
                    return new Promise((resolve) => {
                        // For iOS, always return true since we use Universal Link
                        resolve({ 
                            success: true, 
                            supported: true 
                        });
                    });
                },
                
                installEsimProfile: function(activationCode) {
                    return new Promise((resolve, reject) => {
                        try {
                            // Send message to native iOS to open Universal Link
                            window.webkit.messageHandlers.flutterEsimBridge.postMessage({
                                method: 'installEsimProfile',
                                args: activationCode
                            });
                            
                            // Resolve immediately as we're opening external browser
                            resolve({ 
                                success: true, 
                                message: 'Opening eSIM setup in browser. Please complete the installation and return to the app.' 
                            });
                        } catch (e) {
                            console.error('Error calling installEsimProfile:', e);
                            reject({ 
                                success: false, 
                                error: 'Bridge error: ' + e.message 
                            });
                        }
                    });
                },
                
                openUniversalLink: function(activationCode) {
                    // Alias for installEsimProfile
                    return this.installEsimProfile(activationCode);
                }
            };
            
            // Alias for compatibility
            window.FlutterEsimBridgeHelper = window.FlutterEsimBridge;
            
            console.log('✅ iOS FlutterEsimBridge injected successfully');
            console.log('Platform: iOS | Method: Universal Link');
            
            // Dispatch ready event
            window.dispatchEvent(new Event('flutterEsimBridgeReady'));
        })();
        """
        
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("JS injection error: \(error)")
            } else {
                print("✅ JS Bridge injected successfully")
            }
        }
    }
    
    private func handleInstallEsimProfile(activationCode: String, webView: WKWebView?) {
        // Build Universal Link
        let encodedCode = activationCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? activationCode
        let urlString = "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encodedCode)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Failed to create Universal Link")
            return
        }
        
        print("📲 Opening eSIM Universal Link: \(urlString)")
        
        // Open in external browser
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ Universal Link opened successfully")
                } else {
                    print("❌ Failed to open Universal Link")
                }
            }
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func reload() {
        _webView.reload()
    }
    
    func canGoBack() -> Bool {
        return _webView.canGoBack
    }
    
    func goBack() {
        _webView.goBack()
    }
}
