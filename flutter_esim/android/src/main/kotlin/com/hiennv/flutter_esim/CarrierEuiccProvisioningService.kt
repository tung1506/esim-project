package com.hiennv.flutter_esim

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.service.euicc.ICarrierEuiccProvisioningService
import android.service.euicc.IGetActivationCodeCallback

class CarrierEuiccProvisioningService : Service() {

    private val binder = object : ICarrierEuiccProvisioningService.Stub() {
        override fun getActivationCode(callback: IGetActivationCodeCallback) {
            val code = ActivationCodeStore.get()
            FlutterEsimPlugin.sendEvent(
                "debug",
                mapOf(
                    "stage" to "getActivationCode_called",
                    "hasCode" to (code != null),
                    "codeLength" to (code?.length ?: 0)
                )
            )
            
            if (code.isNullOrBlank()) {
                callback.onFailure(-1, "No activation code available")
                FlutterEsimPlugin.sendEvent(
                    "status",
                    mapOf("stage" to "activation_code_missing")
                )
            } else {
                callback.onSuccess(code)
                FlutterEsimPlugin.sendEvent(
                    "status",
                    mapOf(
                        "stage" to "activation_code_provided",
                        "codeLength" to code.length
                    )
                )
            }
        }

        override fun getActivationCodeForEid(eid: String, callback: IGetActivationCodeCallback) {
            val code = ActivationCodeStore.get()
            FlutterEsimPlugin.sendEvent(
                "debug",
                mapOf(
                    "stage" to "getActivationCodeForEid_called",
                    "eid" to eid,
                    "hasCode" to (code != null),
                    "codeLength" to (code?.length ?: 0)
                )
            )
            
            if (code.isNullOrBlank()) {
                callback.onFailure(-2, "No activation code for EID")
                FlutterEsimPlugin.sendEvent(
                    "status",
                    mapOf("stage" to "activation_code_missing_for_eid", "eid" to eid)
                )
            } else {
                callback.onSuccess(code)
                FlutterEsimPlugin.sendEvent(
                    "status",
                    mapOf(
                        "stage" to "activation_code_provided_for_eid",
                        "eid" to eid,
                        "codeLength" to code.length
                    )
                )
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        FlutterEsimPlugin.sendEvent(
            "debug",
            mapOf(
                "stage" to "service_bound",
                "action" to (intent?.action ?: "unknown")
            )
        )
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        FlutterEsimPlugin.sendEvent(
            "debug",
            mapOf("stage" to "service_created")
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        FlutterEsimPlugin.sendEvent(
            "debug",
            mapOf("stage" to "service_destroyed")
        )
    }
}
