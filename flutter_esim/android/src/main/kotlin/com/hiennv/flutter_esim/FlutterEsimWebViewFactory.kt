package com.hiennv.flutter_esim

import android.content.Context
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

private const val TAG = "FlutterEsimWebView"

class FlutterEsimWebViewFactory(
    private val messenger: BinaryMessenger,
    private val methodChannel: MethodChannel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any>
        val url = creationParams?.get("url") as? String ?: ""
        return FlutterEsimWebView(context, url, messenger, methodChannel)
    }
}

class FlutterEsimWebView(
    context: Context,
    private val initialUrl: String,
    private val messenger: BinaryMessenger,
    private val methodChannel: MethodChannel
) : PlatformView {

    private val webView: WebView = WebView(context).apply {
        settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            allowFileAccess = true
            allowContentAccess = true
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            loadWithOverviewMode = true
            useWideViewPort = true
        }

        // Enable remote debugging
        WebView.setWebContentsDebuggingEnabled(true)

        webViewClient = FlutterEsimWebViewClient(methodChannel)
        webChromeClient = WebChromeClient()

        // Add JavaScript Interface for Bridge
        addJavascriptInterface(
            FlutterEsimJsBridge(methodChannel),
            "FlutterEsimBridge_Native"
        )

        // Load initial URL
        loadUrl(initialUrl)
        Log.d(TAG, "Loading URL: $initialUrl")
    }

    override fun getView(): WebView = webView

    override fun dispose() {
        webView.destroy()
    }

    fun reload() {
        webView.reload()
    }

    fun canGoBack(): Boolean = webView.canGoBack()

    fun goBack() {
        webView.goBack()
    }
}

class FlutterEsimWebViewClient(
    private val methodChannel: MethodChannel
) : WebViewClient() {

    override fun onPageStarted(view: WebView, url: String, favicon: android.graphics.Bitmap?) {
        super.onPageStarted(view, url, favicon)
        Log.d(TAG, "Page started: $url")
        
        methodChannel.invokeMethod("onPageStarted", url)
    }

    override fun onPageFinished(view: WebView, url: String) {
        super.onPageFinished(view, url)
        Log.d(TAG, "Page finished: $url")
        
        // Inject JS Bridge after page loads
        injectJsBridge(view)
        
        methodChannel.invokeMethod("onPageFinished", url)
    }

    override fun onReceivedError(
        view: WebView,
        request: WebResourceRequest,
        error: WebResourceError
    ) {
        super.onReceivedError(view, request, error)
        val errorMessage = "Error ${error.errorCode}: ${error.description}"
        Log.e(TAG, errorMessage)
        
        methodChannel.invokeMethod("onError", errorMessage)
    }

    private fun injectJsBridge(webView: WebView) {
        val jsCode = """
            (function() {
                console.log('Injecting FlutterEsimBridge...');
                
                window.FlutterEsimBridge = {
                    isSupportESim: function() {
                        return new Promise((resolve, reject) => {
                            try {
                                var resultStr = FlutterEsimBridge_Native.isSupportESim();
                                var result = JSON.parse(resultStr);
                                resolve(result);
                            } catch (e) {
                                console.error('Error calling isSupportESim:', e);
                                reject({ success: false, error: 'Bridge error: ' + e.message });
                            }
                        });
                    },
                    
                    installEsimProfile: function(activationCode) {
                        return new Promise((resolve, reject) => {
                            try {
                                var resultStr = FlutterEsimBridge_Native.installEsimProfile(activationCode);
                                var result = JSON.parse(resultStr);
                                resolve(result);
                            } catch (e) {
                                console.error('Error calling installEsimProfile:', e);
                                reject({ success: false, error: 'Bridge error: ' + e.message });
                            }
                        });
                    }
                };
                
                // Alias for compatibility
                window.FlutterEsimBridgeHelper = window.FlutterEsimBridge;
                
                console.log('✅ FlutterEsimBridge injected successfully');
                console.log('FlutterEsimBridge_Native available:', typeof FlutterEsimBridge_Native !== 'undefined');
                
                // Dispatch ready event
                window.dispatchEvent(new Event('flutterEsimBridgeReady'));
            })();
        """.trimIndent()

        webView.evaluateJavascript(jsCode) { result ->
            Log.d(TAG, "JS Bridge injected, result: $result")
        }
    }
}

class FlutterEsimJsBridge(
    private val methodChannel: MethodChannel
) {
    @JavascriptInterface
    fun isSupportESim(): String {
        Log.d(TAG, "JS called: isSupportESim")
        return callMethodSync("isSupportESim", "")
    }

    @JavascriptInterface
    fun installEsimProfile(activationCode: String): String {
        Log.d(TAG, "JS called: installEsimProfile with code length: ${activationCode.length}")
        return callMethodSync("installEsimProfile", activationCode)
    }

    private fun callMethodSync(method: String, args: String): String {
        return try {
            var result: String? = null
            val latch = java.util.concurrent.CountDownLatch(1)
            
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                methodChannel.invokeMethod(method, if (args.isEmpty()) null else args, object : MethodChannel.Result {
                    override fun success(r: Any?) {
                        result = r as? String ?: "{\"success\":false,\"error\":\"Invalid result\"}"
                        latch.countDown()
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        result = "{\"success\":false,\"error\":\"$errorMessage\"}"
                        latch.countDown()
                    }

                    override fun notImplemented() {
                        result = "{\"success\":false,\"error\":\"Method not implemented\"}"
                        latch.countDown()
                    }
                })
            }
            
            // Wait for result (max 10 seconds)
            latch.await(10, java.util.concurrent.TimeUnit.SECONDS)
            
            result ?: "{\"success\":false,\"error\":\"Timeout\"}"
        } catch (e: Exception) {
            Log.e(TAG, "Error calling method $method: ${e.message}", e)
            "{\"success\":false,\"error\":\"${e.message}\"}"
        }
    }
}
