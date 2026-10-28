package com.felnanuke.google_cast.extensions

/**
 * Extension class for Google Cast media information.
 *
 * The HLS segment format hints are required by the Default Media Receiver to
 * demux fragmented-MP4 HLS streams (e.g. PeerTube VOD): without the hint the
 * receiver cannot demux the fMP4 segments and stays stuck in LOADING.
 *
 * The hints travel with the media information inside the `customData` map
 * (using the same key names the Dart side already uses for the map based
 * payloads) and are removed from the payload forwarded to the receiver.
 */
class GoogleCastMediaInfoExtensions {
    companion object {
        /**
         * Key used to carry the HLS audio segment format inside `customData`.
         */
        const val HLS_SEGMENT_FORMAT_KEY = "hlsSegmentFormat"

        /**
         * Key used to carry the HLS video segment format inside `customData`.
         */
        const val HLS_VIDEO_SEGMENT_FORMAT_KEY = "hlsVideoSegmentFormat"

        /**
         * Maps the Flutter `CastHlsSegmentFormat` enum name to the string the
         * Cast SDK / receiver expects (`MediaInfo.Builder.setHlsSegmentFormat`
         * takes a String in play-services-cast). Returns null for unknown /
         * `none` so the field is simply left unset.
         */
        fun hlsSegmentFormatFromName(name: String?): String? = when (name) {
            "aac" -> "aac"
            "ac3" -> "ac3"
            "mp3" -> "mp3"
            "ts" -> "ts"
            "tsAac" -> "ts_aac"
            "eAc3" -> "e-ac3"
            "fmp4" -> "fmp4"
            else -> null
        }

        /**
         * Maps the Flutter `HlsVideoSegmentFormat` enum name to the string the
         * Cast SDK / receiver expects.
         */
        fun hlsVideoSegmentFormatFromName(name: String?): String? = when (name) {
            "mpeg2Ts" -> "mpeg2_ts"
            "fmp4" -> "fmp4"
            else -> null
        }

        /**
         * Reverse of [hlsSegmentFormatFromName]: maps the Cast SDK string back
         * to the Flutter `CastHlsSegmentFormat` enum name.
         */
        fun hlsSegmentFormatToName(value: String?): String? = when (value) {
            "aac" -> "aac"
            "ac3" -> "ac3"
            "mp3" -> "mp3"
            "ts" -> "ts"
            "ts_aac" -> "tsAac"
            "e-ac3" -> "eAc3"
            "fmp4" -> "fmp4"
            else -> null
        }

        /**
         * Reverse of [hlsVideoSegmentFormatFromName]: maps the Cast SDK string
         * back to the Flutter `HlsVideoSegmentFormat` enum name.
         */
        fun hlsVideoSegmentFormatToName(value: String?): String? = when (value) {
            "mpeg2_ts" -> "mpeg2Ts"
            "fmp4" -> "fmp4"
            else -> null
        }

        /**
         * Removes the HLS segment format hints from the custom data so they
         * are not forwarded to the receiver as custom metadata.
         */
        fun withoutHlsSegmentFormats(customData: Map<String, Any?>): Map<String, Any?> =
            customData.filterKeys { key ->
                key != HLS_SEGMENT_FORMAT_KEY && key != HLS_VIDEO_SEGMENT_FORMAT_KEY
            }
    }
}
