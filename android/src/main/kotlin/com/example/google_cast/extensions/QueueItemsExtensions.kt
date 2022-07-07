package com.example.google_cast.extensions

import android.media.MediaDescription
import android.media.session.MediaSession
import android.os.Build
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaQueueItem

object QueueItemBuilder {

    fun fromMap(map: Map<String, Any?>): MediaQueueItem? {
//        'activeTrackIds': activeTrackIds,
//        'autoplay': autoPlay,
//        'customData': customData,
//        'itemId': itemId,
//        'media': mediaInformation.toMap(),
//        'playbackDuration': playbackDuration?.inSeconds,
//        'preloadTime': preLoadTime?.inSeconds,
//        'startTime': startTime?.inSeconds,

        val activeTrackIds = map["activeTrackIds"] as List<*>?
        val id = map["itemId"]
        var mediaInfo: MediaInfo? =
            GoogleCastMediaInfo.fromMap(map["media"] as Map<String, Any?>) ?: return null
        var builder = MediaQueueItem.Builder(mediaInfo!!)
        return builder.build()

    }

    fun listFromMap(items: List<Map<String, Any?>>): List<MediaQueueItem> {
        val list = mutableListOf<MediaQueueItem>()
        for (item in items) {
            val queueItem = QueueItemBuilder.fromMap(item)
            if (queueItem != null)
                list.add(queueItem)
        }
        return  list

    }

}