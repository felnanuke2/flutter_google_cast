
import android.content.Context
import com.example.google_cast.R
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider



 class GoogleCastOptionsProvider : OptionsProvider {
     companion object{
         lateinit var options: CastOptions
     }
    override fun getCastOptions(context: Context): CastOptions {

        return options
    }

    override fun getAdditionalSessionProviders(p0: Context): MutableList<SessionProvider>? {
        return null
    }
}