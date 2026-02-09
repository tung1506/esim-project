package com.hiennv.flutter_esim

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Context.EUICC_SERVICE
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.lang.ref.WeakReference
import com.hiennv.flutter_esim.FlutterEsimWebViewFactory

/** FlutterEsimPlugin */
class FlutterEsimPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {

        private fun <T, C : MutableCollection<WeakReference<T>>> C.reapCollection(): C {
            this.removeAll { it.get() == null }
            return this
        }

        @SuppressLint("StaticFieldLeak") private lateinit var instance: FlutterEsimPlugin

        private val methodChannels = mutableMapOf<BinaryMessenger, MethodChannel>()
        private val eventChannels = mutableMapOf<BinaryMessenger, EventChannel>()
        private val eventHandlers = mutableListOf<WeakReference<EventCallbackHandler>>()

        fun sendEvent(event: String, body: Map<String, Any>) {
            eventHandlers.reapCollection().forEach { it.get()?.send(event, body) }
        }

        fun initSharedInstance(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
            if (!::instance.isInitialized) {
                instance = FlutterEsimPlugin()
                instance.context = flutterPluginBinding.applicationContext
            }

            val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_esim")
            methodChannels[flutterPluginBinding.binaryMessenger] = channel
            channel.setMethodCallHandler(instance)

            val events = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_esim_events")
            val handler = EventCallbackHandler()
            eventHandlers.add(WeakReference(handler))
            events.setStreamHandler(handler)
            eventChannels[flutterPluginBinding.binaryMessenger] = events
        }
    }

    private var activity: Activity? = null
    private var context: Context? = null
    private var mgr: EuiccManager? = null
    private var activityPluginBinding: ActivityPluginBinding? = null

    private val REQUEST_CODE_INSTALL_ESIM = 1001

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        initSharedInstance(flutterPluginBinding)
        
        // Register WebView platform view
        val webViewChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.flutter_esim/webview")
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "com.flutter_esim/webview",
                FlutterEsimWebViewFactory(flutterPluginBinding.binaryMessenger, webViewChannel)
            )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isSupportESim" -> {
                    sendEvent("debug", mapOf("stage" to "isSupportESim_called"))
                    
                    // Check Android version - need Android 9+ (API 28+) for eSIM
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                        sendEvent("debug", mapOf(
                            "stage" to "isSupportESim_unsupported_sdk",
                            "sdk" to Build.VERSION.SDK_INT
                        ))
                        result.success(false)
                        return
                    }
                    
                    // Check if EuiccManager is available
                    val euiccMgr = if (mgr != null) {
                        mgr
                    } else {
                        try {
                            context?.getSystemService(EUICC_SERVICE) as? EuiccManager
                        } catch (e: Exception) {
                            null
                        }
                    }
                    
                    if (euiccMgr == null) {
                        sendEvent("debug", mapOf(
                            "stage" to "isSupportESim_no_euicc_manager",
                            "sdk" to Build.VERSION.SDK_INT
                        ))
                        result.success(false)
                        return
                    }
                    
                    // Check if device hardware supports eSIM
                    val isEnabled = euiccMgr.isEnabled
                    
                    sendEvent("debug", mapOf(
                        "stage" to "isSupportESim_result",
                        "isEnabled" to isEnabled,
                        "sdk" to Build.VERSION.SDK_INT,
                        "euiccId" to (euiccMgr.eid ?: "null")
                    ))
                    
                    result.success(isEnabled)
                }
                "installEsimProfile" -> {
                    val activationCode = (call.arguments as? HashMap<*, *>)?.get("profile") as? String
                    
                    if (activationCode.isNullOrBlank()) {
                        sendEvent("fail", mapOf(
                            "stage" to "empty_activation_code",
                            "reason" to "Activation code is empty"
                        ))
                        result.error("EMPTY_CODE", "Activation code is empty", null)
                        return
                    }

                    sendEvent("status", mapOf(
                        "stage" to "install_requested",
                        "sdk" to Build.VERSION.SDK_INT,
                        "codeLength" to activationCode.length
                    ))

                    // Check SDK version - need Android 9+ (API 28+)
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                        sendEvent("unsupport", mapOf(
                            "reason" to "SDK<28",
                            "sdk" to Build.VERSION.SDK_INT
                        ))
                        openEsimSettingsFallback()
                        result.success(false)
                        return
                    }

                    // Check if EuiccManager is available
                    if (mgr == null) {
                        sendEvent("fail", mapOf(
                            "reason" to "EuiccManager_null",
                            "sdk" to Build.VERSION.SDK_INT
                        ))
                        result.error("EUICC_NULL", "EuiccManager is null", null)
                        return
                    }

                    // Check if eSIM is enabled
                    if (!mgr!!.isEnabled) {
                        sendEvent("unsupport", mapOf(
                            "reason" to "EUICC_DISABLED"
                        ))
                        openEsimSettingsFallback()
                        result.success(false)
                        return
                    }

                    // For Android 14+ (API 34+), use the new approach with AIDL service
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        startEsimActivationFlow(activationCode)
                        result.success(true)
                    } else {
                        // For older versions, fall back to manual settings
                        sendEvent("status", mapOf(
                            "stage" to "fallback_to_settings",
                            "reason" to "SDK<34",
                            "sdk" to Build.VERSION.SDK_INT
                        ))
                        openEsimSettingsFallback()
                        result.success(false)
                    }
                }
                "instructions" -> {
                    result.success(
                        "1. Save QR Code\n" +
                        "2. Go to Settings on your device\n" +
                        "3. TAP Connections\n" +
                        "4. TAP SIM Manager\n" +
                        "5. TAP Add eSIM\n" +
                        "6. TAP Scan QR code from service provider\n" +
                        "7. TAP Enter activation code\n" +
                        "8. ENTER the activation code found in the eSIM details\n" +
                        "9. TAP Connect\n" +
                        "10. TAP Add"
                    )
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            sendEvent("fail", mapOf(
                "stage" to "method_exception",
                "error" to (error.message ?: ""),
                "stackTrace" to (error.stackTraceToString())
            ))
            result.error("EXCEPTION", error.message, null)
        }
    }

    private fun startEsimActivationFlow(activationCode: String) {
        try {
            sendEvent("status", mapOf(
                "stage" to "storing_activation_code",
                "codeLength" to activationCode.length
            ))
            
            // Store activation code for the service to retrieve
            ActivationCodeStore.set(activationCode)

            sendEvent("status", mapOf("stage" to "launching_euicc_activation"))

            // Launch the system eSIM activation flow
            val intent = Intent(EuiccManager.ACTION_START_EUICC_ACTIVATION).apply {
                putExtra(EuiccManager.EXTRA_USE_QR_SCANNER, false)
            }

            activity?.startActivityForResult(intent, REQUEST_CODE_INSTALL_ESIM)

            sendEvent("status", mapOf(
                "stage" to "activation_intent_launched",
                "requestCode" to REQUEST_CODE_INSTALL_ESIM
            ))
        } catch (e: Exception) {
            sendEvent("fail", mapOf(
                "stage" to "launch_failed",
                "error" to (e.message ?: ""),
                "stackTrace" to e.stackTraceToString()
            ))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        sendEvent("debug", mapOf(
            "stage" to "onActivityResult",
            "requestCode" to requestCode,
            "resultCode" to resultCode,
            "expectedRequestCode" to REQUEST_CODE_INSTALL_ESIM,
            "RESULT_OK" to Activity.RESULT_OK,
            "RESULT_CANCELED" to Activity.RESULT_CANCELED
        ))

        if (requestCode == REQUEST_CODE_INSTALL_ESIM) {
            when (resultCode) {
                Activity.RESULT_OK -> {
                    sendEvent("success", mapOf(
                        "stage" to "esim_installed",
                        "message" to "eSIM installed successfully"
                    ))
                    ActivationCodeStore.clear()
                }
                Activity.RESULT_CANCELED -> {
                    sendEvent("fail", mapOf(
                        "stage" to "esim_installation_canceled",
                        "reason" to "User canceled",
                        "resultCode" to resultCode
                    ))
                    ActivationCodeStore.clear()
                }
                else -> {
                    sendEvent("unknown", mapOf(
                        "stage" to "unexpected_result_code",
                        "resultCode" to resultCode,
                        "data" to (data?.extras?.keySet()?.joinToString() ?: "no_extras")
                    ))
                    ActivationCodeStore.clear()
                }
            }
            return true
        }
        return false
    }

    private fun openEsimSettingsFallback() {
        try {
            val possibleIntents = listOf(
                Intent("android.settings.ESIM_SETTINGS"),
                Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS),
                Intent(Settings.ACTION_WIRELESS_SETTINGS)
            )

            for (intent in possibleIntents) {
                if (activity?.packageManager?.let { intent.resolveActivity(it) } != null) {
                    sendEvent("status", mapOf(
                        "stage" to "opening_settings",
                        "action" to (intent.action ?: "unknown")
                    ))
                    activity?.startActivity(intent)
                    return
                }
            }

            sendEvent("fail", mapOf(
                "stage" to "settings_not_available",
                "reason" to "eSIM settings not available on this device"
            ))
        } catch (e: Exception) {
            sendEvent("fail", mapOf(
                "stage" to "settings_open_failed",
                "error" to (e.message ?: "")
            ))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannels.remove(binding.binaryMessenger)?.setMethodCallHandler(null)
        eventChannels.remove(binding.binaryMessenger)?.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        instance.context = binding.activity.applicationContext
        instance.activity = binding.activity
        instance.activityPluginBinding = binding
        
        // Register activity result listener
        binding.addActivityResultListener(this)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            instance.mgr = instance.context?.getSystemService(EUICC_SERVICE) as? EuiccManager
            sendEvent("debug", mapOf(
                "stage" to "attached_to_activity",
                "hasEuiccManager" to (instance.mgr != null),
                "isEnabled" to (instance.mgr?.isEnabled ?: false)
            ))
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityPluginBinding?.removeActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        instance.context = binding.activity.applicationContext
        instance.activity = binding.activity
        instance.activityPluginBinding = binding
        
        // Re-register activity result listener
        binding.addActivityResultListener(this)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            instance.mgr = instance.context?.getSystemService(EUICC_SERVICE) as? EuiccManager
        }
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding?.removeActivityResultListener(this)
        activityPluginBinding = null
    }

    class EventCallbackHandler : EventChannel.StreamHandler {

        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            eventSink = sink
        }

        fun send(event: String, body: Map<String, Any>) {
            val data = mapOf("event" to event, "body" to body)
            Handler(Looper.getMainLooper()).post { eventSink?.success(data) }
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }
}
