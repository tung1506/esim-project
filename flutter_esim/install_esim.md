🧩 The Problem
Android introduced eSIM support with Android 9 (API 28) via the EuiccManager API.
However, when you try to integrate it, you quickly notice that critical parts of the flow (like AIDL provisioning) are poorly documented or missing entirely.

This post explains how to bridge that gap with a working example.

⚙️ High-Level Overview
Here’s what the process looks like:

Fetch the eSIM profile activation code usually looks like :
// Dummy LPA
LPA:1$consumer.e-sim.global$TN20241211123456784179E1
Pass it to the system eSIM installer (LPA).
Expose it via a custom AIDL-based provisioning service.
Trigger the system activation flow.
💡 Step 1: Activity Setup
We’ll start by launching the eSIM activation intent when it’s ready. (I assume you already have the activation code provided by your esim Carrier).


@AndroidEntryPoint
class ESimInstaller : AppCompatActivity() {
  

private val launcher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        when (result.resultCode) {
            RESULT_OK -> Toast.makeText(this, "eSIM installed", Toast.LENGTH_SHORT).show()
            RESULT_CANCELED -> Toast.makeText(this, "eSIM install cancelled", Toast.LENGTH_SHORT).show()
            else -> finish()
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
         
        startEsimActivationFlow(YOUR_LPA_ACTIVATION_CODE)
         
    }
}
Once the data is available, we call startWithCode() to trigger the installation.

⚡ Step 2: Trigger eSIM Installation
Here’s the key part — launching the system eSIM installer using EuiccManager.

private fun startEsimActivationFlow(lpaCode: String) {
    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.TIRAMISU) {
        Toast.makeText(this, "eSIM installation isn’t supported through the app. Please install manually from settings.", Toast.LENGTH_SHORT).show()
        openEsimSettings()
        return
    }

ActivationCodeStore.set(lpaCode)

    val intent = Intent(EuiccManager.ACTION_START_EUICC_ACTIVATION).apply {
        putExtra(EuiccManager.EXTRA_USE_QR_SCANNER, false)
    }
    launcher.launch(intent)
}
We temporarily store the activation code and let the system LPA (Local Profile Assistant) handle the actual provisioning.

🧠 Step 3: The Role of AIDL in eSIM Activation
Now, here’s where many developers get stuck — understanding why AIDL is needed.

When you trigger the eSIM activation intent, the system’s LPA (Local Profile Assistant) tries to fetch the activation code from your app.
But how does it communicate with your app securely and efficiently?
That’s where AIDL (Android Interface Definition Language) comes in.

👉 Why AIDL?
AIDL defines the IPC (Inter-Process Communication) contract between:

The system process (LPA) that installs the eSIM, and
Your app, which provides the activation code (LPA URI).
In short:

AIDL acts as a bridge between your app and the Android system service that performs the eSIM installation.

Without it, the system has no way to get your activation code programmatically.

🧾 Step 4: Define AIDL Interfaces
You’ll need two AIDL files in your aidl directory and can’t directly create AIDL files as you have enable it.

Add aidl flag in your app level build.gradleorbuild.gradle.kts

buildFeatures {
        aidl = true
    }
After successful sync, Go to:
File > New > AIDL > AIDL File and create these:

// ICarrierEuiccProvisioningService.aidl
package android.service.euicc;

import android.service.euicc.IGetActivationCodeCallback;

interface ICarrierEuiccProvisioningService {
    void getActivationCode(in IGetActivationCodeCallback callback);
    void getActivationCodeForEid(in String eid, in IGetActivationCodeCallback callback);
}
// IGetActivationCodeCallback.aidl
package android.service.euicc;

interface IGetActivationCodeCallback {
    void onSuccess(String activationCode);
    void onFailure(int errorCode, String errorMessage);
}
These define how your app shares the activation code with the system securely.

🔧 Step 5: Implement the Provisioning Service
Now we implement the service that responds to the system’s request for the activation code.

// CarrierEuiccProvisioningService.kt

class CarrierEuiccProvisioningService : Service() {
    private val binder = object : ICarrierEuiccProvisioningService.Stub() {
        override fun getActivationCode(callback: IGetActivationCodeCallback) {
            val code = ActivationCodeStore.get()
            if (code.isNullOrBlank()) {
                callback.onFailure(-1, "No activation code available")
            } else {
                callback.onSuccess(code)
            }
        }

override fun getActivationCodeForEid(eid: String, callback: IGetActivationCodeCallback) {
            val code = ActivationCodeStore.get()
            if (code.isNullOrBlank()) {
                callback.onFailure(-2, "No activation code for EID")
            } else {
                callback.onSuccess(code)
            }
        }
    }
    override fun onBind(intent: Intent?): IBinder = binder
}
And declare it in your manifest:

<service
    android:name=".CarrierEuiccProvisioningService"
    android:exported="true"
    android:enabled="true">
    <intent-filter>
        <action android:name="android.service.euicc.action.BIND_CARRIER_PROVISIONING_SERVICE" />
    </intent-filter>
</service>
When the eSIM activation flow starts, Android binds to this service automatically, calls getActivationCode(), and installs the eSIM using your provided LPA code.

⚠️ Step 6: Handle Unsupported Devices
Not all Android devices (or carriers) support eSIM activation through apps.
In those cases, redirect users to eSIM settings manually:

private fun openEsimSettings() {
    val possibleIntents = listOf(
        Intent("android.settings.ESIM_SETTINGS"),
        Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS),
        Intent(Settings.ACTION_WIRELESS_SETTINGS)
    )

for (intent in possibleIntents) {
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
            return
        }
    }
    Toast.makeText(this, "eSIM settings not available on this device", Toast.LENGTH_LONG).show()
}
💬 Pro Tip
🧩 Test on Pixel Devices First
Pixel devices (Pixel 4 and above) provide the cleanest, fully compliant eSIM stack — making debugging and validation much easier.
Other OEMs may restrict or modify eSIM behavior through carrier locks or custom UIs.

Always ensure your activation code follows the correct format:

LPA:1$<SMDP+ host>$<token>
✅ Key Takeaways
The official documentation is incomplete — especially around AIDL provisioning.
AIDL is the core communication bridge between your app and the system’s eSIM installer.
Implement a CarrierEuiccProvisioningService to supply your activation code dynamically.
Use fallback logic for unsupported devices or Android versions.
The flow is clean once understood: Fetch → Store → Trigger → Respond.
🎯 Conclusion
That’s the simplest, fully working eSIM installation flow for Android.
You don’t need to reverse-engineer hidden APIs or rely on vague examples — this setup works cleanly with the system LPA.

If you found this helpful, share it with other Android developers who are struggling with undocumented APIs — and save them a few hours of trial and error!