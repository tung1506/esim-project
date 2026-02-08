package com.hiennv.flutter_esim

object ActivationCodeStore {
    private var activationCode: String? = null

    fun set(code: String) {
        activationCode = code
    }

    fun get(): String? {
        return activationCode
    }

    fun clear() {
        activationCode = null
    }
}
