import Flutter
import UIKit

public class FlutterEsimPlugin: NSObject, FlutterPlugin {
    
    public private(set) static var sharedInstance: FlutterEsimPlugin!
    
    private var streamHandlers: WeakArray<EventCallbackHandler> = WeakArray([])
    
    private var esimChecker: EsimChecker
    
    private func sendEvent(_ event: String, _ body: [String : Any?]?) {
        streamHandlers.reap().forEach { handler in
            handler?.send(event, body ?? [:])
        }
    }
    
    private static func createMethodChannel(messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
        return FlutterMethodChannel(name: "flutter_esim", binaryMessenger: messenger)
    }
    
    private static func createEventChannel(messenger: FlutterBinaryMessenger) -> FlutterEventChannel {
        return FlutterEventChannel(name: "flutter_esim_events", binaryMessenger: messenger)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("🔧 FlutterEsimPlugin: Registering plugin...")
        
        let instance = FlutterEsimPlugin()
        instance.shareHandlers(with: registrar)
        
        // Register WebView Factory for iOS with Hybrid Composition
        let methodChannel = createMethodChannel(messenger: registrar.messenger())
        let factory = FlutterEsimWebViewFactory(
            messenger: registrar.messenger(),
            methodChannel: methodChannel
        )
        
        // CRITICAL: Use Hybrid Composition for iOS
        // This is required for WKWebView to render properly in Flutter
        registrar.register(
            factory, 
            withId: "com.flutter_esim/webview"
        )
        
        print("✅ FlutterEsimPlugin: WebView factory registered with Hybrid Composition")
    }
    
    private func shareHandlers(with registrar: FlutterPluginRegistrar) {
        registrar.addMethodCallDelegate(self, channel: Self.createMethodChannel(messenger: registrar.messenger()))
        let eventsHandler = EventCallbackHandler()
        esimChecker.handler = eventsHandler;
        self.streamHandlers.append(eventsHandler)
        Self.createEventChannel(messenger: registrar.messenger()).setStreamHandler(eventsHandler)
    }
    
    public override init() {
        esimChecker = EsimChecker()
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupportESim":
            let args = call.arguments as? [String];
            result(esimChecker.isSupportESim(supportedModels: args ?? []));
            break;
        case "installEsimProfile":
            // For iOS: Use Universal Link instead of CTCellularPlanProvisioning
            guard let args = call.arguments else {
                result(false)
                return
            }
            
            var activationCode: String?
            
            // Handle both String and Dictionary arguments
            if let code = args as? String {
                activationCode = code
            } else if let getArgs = args as? [String: Any] {
                activationCode = getArgs["profile"] as? String
            }
            
            guard let code = activationCode, !code.isEmpty else {
                result(false)
                return
            }
            
            // Open Universal Link for iOS
            openEsimUniversalLink(activationCode: code, result: result)
            break;
        case "openUniversalLink":
            // New method for iOS to open eSIM Universal Link
            guard let activationCode = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Activation code is required", details: nil))
                return
            }
            openEsimUniversalLink(activationCode: activationCode, result: result)
            break;
        case  "instructions":
            result(
                "1. Save QR Code\n" +
                "2. On your device, go to Settings\n" +
                "3. Tap Cellular or Mobile\n" +
                "4. Tap Add Cellular Plan or Add Mobile Data Plan\n" +
                "5. Tap Add eSIM\n" +
                "6. Tap Use QR Code\n" +
                "7. Tap Open Photos\n" +
                "8. Tap Open Photos\n" +
                "9. SELECT the saved QR code\n" +
                "10. TAP Continue twice\n" +
                "11. WAIT a few minutes for your eSIM to activate\n" +
                "12. TAP Done"
            )
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func openEsimUniversalLink(activationCode: String, result: @escaping FlutterResult) {
        // Build Universal Link with activation code
        let encodedCode = activationCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? activationCode
        let urlString = "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encodedCode)"
        
        guard let url = URL(string: urlString) else {
            result(false)
            return
        }
        
        print("📲 Opening eSIM Universal Link: \(urlString)")
        
        // Open URL in external browser (Safari/Chrome/etc)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        } else {
            let success = UIApplication.shared.openURL(url)
            result(success)
        }
    }
}

class EventCallbackHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    public func send(_ event: String, _ body: Any) {
        let data: [String : Any] = [
            "event": event,
            "body": body
        ]
        eventSink?(data)
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

