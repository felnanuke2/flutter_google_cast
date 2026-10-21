package com.felnanuke.google_cast

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

class GoogleCastOptionsProvider : OptionsProvider {

    companion object {
        lateinit var options: CastOptions

        var stopCastingOnAppTerminated: Boolean = false
            set(value) {
                CastDebugLog.d("GoogleCastOptionsProvider", "stopCastingOnAppTerminated: $field -> $value")
                field = value
            }
    }

    override fun getCastOptions(context: Context): CastOptions {
        CastDebugLog.d("GoogleCastOptionsProvider", "getCastOptions: Providing CastOptions to framework, appId=${options.receiverApplicationId}")
        return options
    }

    override fun getAdditionalSessionProviders(context: Context): MutableList<SessionProvider>? {
        CastDebugLog.d("GoogleCastOptionsProvider", "getAdditionalSessionProviders: Returning null (no additional providers)")
        return null
    }
}
