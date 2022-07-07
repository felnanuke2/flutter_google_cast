package com.example.google_cast.extensions

import android.media.MediaDescription
import android.media.session.MediaSession
import android.os.Build
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaQueueItem
import org.json.JSONObject

object QueueItemBuilder {

    fun fromMap(map: Map<String, Any?>): MediaQueueItem? {
        val activeTrackIds = map["activeTrackIds"] as LongArray?
        val startTime = map["startTime"] as Int?
        val id = map["itemId"] as Int?
        val preloadTime = map["preloadTime"] as Int?
        val playbackDuration = map["playbackDuration"] as Int?
        val customD = map["customData"] as Map<String, Any?>?
        val autoPlay = map["autoPlay"] as Boolean? ?: true
        var mediaInfo: MediaInfo? =
            GoogleCastMediaInfo.fromMap(map["media"] as Map<String, Any?>) ?: return null
        var builder = MediaQueueItem.Builder(mediaInfo!!)
        if (activeTrackIds != null)
            builder.setActiveTrackIds(activeTrackIds)
        if (id != null)
            builder.setItemId(id)
        if (preloadTime != null)
            builder.setPreloadTime(preloadTime.toDouble())
        if (startTime != null)
            builder.setPreloadTime(startTime.toDouble())
        if (playbackDuration != null)
            builder.setPlaybackDuration(playbackDuration.toDouble())
        if (customD != null) {
            val customData = JSONObject(customD)
            builder.setCustomData(customData)
        }
        builder.setAutoplay(autoPlay)
        return builder.build()

    }

    fun listFromMap(items: List<Map<String, Any?>>): List<MediaQueueItem> {
        val list = mutableListOf<MediaQueueItem>()
        for (item in items) {
            val queueItem = QueueItemBuilder.fromMap(item)
            if (queueItem != null)
                list.add(queueItem)
        }
        return list

    }

}