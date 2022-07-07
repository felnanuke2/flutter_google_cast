package com.example.google_cast.extensions


import android.net.Uri
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.common.images.WebImage

class GoogleCastMetadataBuilder {
    companion object {
        fun fromMap(args: Map<String, Any?>): MediaMetadata? {

            var map = args.toMutableMap()
            if (map.isEmpty()) return null
            val metadata = MediaMetadata()
            for (item in map) {
                val datesKey = listOf(
                    "releaseDate",
                    "broadcastDate",
                    "creationDateTime",
                    "creationDate"
                )
                if (item.key in datesKey) {
                    metadata.putTimeMillis(item.key, (item.value as Int).toLong())
                    map.remove(item.key)
                }
                when (item.value) {
                    is String -> metadata.putString(item.key, item.value as String)
                    is Int -> metadata.putInt(
                        item.key, item.value as Int
                    )
                    is Double -> metadata.putDouble(item.key, item.value as Double)

                }
            }
            val imagesData = map["images"] as List<Map<String, Any?>>?
            if (imagesData != null) {
                val images = imagesData.map {
                    imageFromMap(it)
                }
                for (image in images) {
                    metadata.addImage(image)
                }
            }
            return metadata
        }

        private fun imageFromMap(args: Map<String, Any?>): WebImage {
            val url = args["url"] as String
            val width = args["width"] as Int?
            val height = args["height"] as Int?
            return WebImage(Uri.parse(url), width ?: 250, height ?: 250)
        }


    }
}