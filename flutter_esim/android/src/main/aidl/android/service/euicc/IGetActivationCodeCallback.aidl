package android.service.euicc;

interface IGetActivationCodeCallback {
    void onSuccess(String activationCode);
    void onFailure(int errorCode, String errorMessage);
}
