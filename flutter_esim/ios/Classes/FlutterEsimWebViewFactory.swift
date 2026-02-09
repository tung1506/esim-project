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
    private var _containerView: UIView
    private var methodChannel: FlutterMethodChannel
    
    private func logToFlutter(_ message: String) {
        // Best-effort logging to Flutter; ignore failures
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.methodChannel.invokeMethod("onLog", arguments: message)
        }
    }
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger,
        methodChannel: FlutterMethodChannel
    ) {
        self.methodChannel = methodChannel
        
        // Create container view with explicit size
        _containerView = UIView(frame: frame)
        _containerView.backgroundColor = UIColor.red
        _containerView.clipsToBounds = true
        
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
        
        // Create webview with container's bounds
        _webView = WKWebView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), configuration: configuration)
        
        super.init()
        
        logToFlutter("iOS WebView init frame=\(frame)")
        
        print("🚀 FlutterEsimWebView initializing...")
        print("🔧 Frame: width=\(frame.width), height=\(frame.height)")
        
        // Use autoresizing mask instead of Auto Layout for Flutter Platform View
        _webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _webView.translatesAutoresizingMaskIntoConstraints = true  // Changed to true
        
        // Add webview to container
        _containerView.addSubview(_webView)
        print("✅ WebView added to container")
        
        // Set delegates
        _webView.navigationDelegate = self
        
        // Enable scrolling
        _webView.scrollView.isScrollEnabled = true
        _webView.scrollView.bounces = true
        _webView.scrollView.backgroundColor = UIColor.clear  // Changed from red
        
        // Set background color
        _webView.isOpaque = true
        _webView.backgroundColor = UIColor.white
        _containerView.backgroundColor = UIColor.white
        
        // Force layout
        _webView.setNeedsLayout()
        _webView.layoutIfNeeded()
        
        // Additional debugging
        print("🔧 Container bounds: \(_containerView.bounds)")
        print("🔧 WKWebView bounds: \(_webView.bounds)")
        print("🔧 Configuration: JavaScript=\(configuration.preferences.javaScriptEnabled)")
        
        // Add script message handlers for JS Bridge
        userContentController.add(self, name: "flutterEsimBridge")
        print("✅ Script message handler registered")
        
        // Parse arguments and load URL
        if let args = args as? [String: Any],
           let url = args["url"] as? String,
           let urlObj = URL(string: url) {
            logToFlutter("Loading URL: \(url)")
            print("🌐 Loading URL: \(url)")
            
            // Load URL after a short delay to ensure view is laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                var request = URLRequest(url: urlObj)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                self._webView.load(request)
                
                // Force redraw
                self._webView.setNeedsDisplay()
                self._containerView.setNeedsDisplay()
            }
        } else {
            logToFlutter("No URL provided in arguments")
            print("⚠️ No URL provided in arguments")
        }
    }
    
    func view() -> UIView {
        return _containerView
    }
    
    // MARK: - Cleanup
    
    deinit {
        logToFlutter("deinit")
        print("🧹 FlutterEsimWebView deallocating...")
        // Cleanup on main thread to prevent crash
        DispatchQueue.main.async { [weak self] in
            self?.cleanupSync()
        }
    }
    
    private func cleanupSync() {
        logToFlutter("cleanupSync")
        // Stop loading first
        _webView.stopLoading()
        
        // Clear delegates
        _webView.navigationDelegate = nil
        
        // Remove script message handlers safely
        _webView.configuration.userContentController.removeAllUserScripts()
        
        // Important: Use removeAllScriptMessageHandlers on iOS 14+
        if #available(iOS 14.0, *) {
            _webView.configuration.userContentController.removeAllScriptMessageHandlers()
        } else {
            // Fallback for older iOS versions
            // Note: This may cause a warning but won't crash
            _webView.configuration.userContentController.removeScriptMessageHandler(forName: "flutterEsimBridge")
        }
        
        // Remove from superview
        _webView.removeFromSuperview()
        
        print("✅ WebView cleaned up safely")
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            logToFlutter("didStart: \(url)")
            print("📍 Page started: \(url)")
            methodChannel.invokeMethod("onPageStarted", arguments: url)
        } else {
            logToFlutter("didStart (url=nil)")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            logToFlutter("didFinish: \(url) size=\(webView.frame.size)")
            print("✅ Page finished: \(url)")
            print("🔍 WebView frame: \(webView.frame)")
            print("🔍 Container frame: \(_containerView.frame)")
            print("🔍 WebView isHidden: \(webView.isHidden)")
            print("🔍 WebView alpha: \(webView.alpha)")
            print("🔍 WebView superview: \(String(describing: webView.superview))")
            print("🔍 Container superview: \(String(describing: _containerView.superview))")
            
            // Check if view is actually visible
            if webView.frame.size.width == 0 || webView.frame.size.height == 0 {
                print("⚠️ WebView has zero size!")
            }
            
            // Check content size
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                if let height = result {
                    print("📏 Content height: \(height)")
                } else if let error = error {
                    print("⚠️ Failed to get content height: \(error)")
                }
            }
            
            // Check if HTML is loaded
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result {
                    print("📄 HTML content length: \(length)")
                } else if let error = error {
                    print("⚠️ Failed to get HTML length: \(error)")
                }
            }
            
            // Inject JS Bridge after page loads
            injectJsBridge(webView: webView)
            methodChannel.invokeMethod("onPageFinished", arguments: url)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logToFlutter("didFail: \(error.localizedDescription)")
        print("❌ Navigation failed: \(error.localizedDescription)")
        let errorMessage = "Error: \(error.localizedDescription)"
        methodChannel.invokeMethod("onError", arguments: errorMessage)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logToFlutter("didFailProvisional: \(error.localizedDescription)")
        print("❌ Provisional navigation failed: \(error.localizedDescription)")
        let errorMessage = "Error: \(error.localizedDescription)"
        methodChannel.invokeMethod("onError", arguments: errorMessage)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let u = navigationAction.request.url?.absoluteString ?? "unknown"
        logToFlutter("navAction: \(u)")
        print("🔗 Navigation action: \(u)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            print("📦 Response status: \(response.statusCode)")
            print("📦 Content-Type: \(response.allHeaderFields["Content-Type"] ?? "unknown")")
        }
        decisionHandler(.allow)
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
