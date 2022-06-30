import 'package:google_cast/entities/media_information.dart';

import '../../entities/media_metadata/cast_media_metadata.dart';

class GoogleCastIOSMediaInformation extends GoogleCastMediaInformation {
  GoogleCastIOSMediaInformation({
    required super.contentId,
    required super.streamType,
    required super.contentType,
    super.atvEntity,
    super.breakClips,
    super.breaks,
    super.contentUrl,
    super.customData,
    super.duration,
    super.entity,
    super.hlsSegmentFormat,
    super.hlsVideoSegmentFormat,
    super.metadata,
    super.startAbsoluteTime,
    super.textTrackStyle,
    super.tracks,
    super.userActionStates,
    super.vmapAdsRequest,
  });

  Map<String, dynamic> toMap() {
    return {
      'atvEntity': atvEntity,
      'breakClips': breakClips?.map((x) => x.toMap()).toList(),
      'contentID': contentId,
      'streamType': streamType.value,
      'contentType': contentType,
      'metadata': metadata?.toMap(),
      'duration': duration?.inSeconds,
      'customData': customData,
      'breaks': breaks?.map((x) => x.toMap()).toList(),
      'contentURL': contentUrl,
      'entity': entity,
      'hlsSegmentFormat': hlsSegmentFormat?.name,
      'hlsVideoSegmentFormat': hlsVideoSegmentFormat?.name,
      'startAbsoluteTime': startAbsoluteTime?.millisecondsSinceEpoch,
      'textTrackStyle': textTrackStyle?.toMap(),
      'tracks': tracks?.map((x) => x.toMap()).toList(),
      'userActionStates': userActionStates?.map((x) => x.toMap()).toList(),
      'vmapAdsRequest': vmapAdsRequest?.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory GoogleCastIOSMediaInformation.fromMap(Map<String, dynamic> map) {
    return GoogleCastIOSMediaInformation(
      atvEntity: map['atvEntity'],
      breakClips: map['breakClips'] != null
          ? List<CastBreakClips>.from(
              map['breakClips']?.map((x) => CastBreakClips.fromMap(x)))
          : null,
      contentId: map['contentId'] ?? '',
      streamType: CastMediaStreamType.values[map['streamType']],
      contentType: map['contentType'] ?? '',
      metadata: map['metadata'] != null
          ? getCastMediaMetadata(Map.from(map['metadata']))
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'].round())
          : null,
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
      breaks: map['breaks'] != null
          ? List<CastBreak>.from(
              map['breaks']?.map((x) => CastBreak.fromMap(x)))
          : null,
      contentUrl: map['contentUrl'],
      entity: map['entity'],
      hlsSegmentFormat: map['hlsSegmentFormat'] != null
          ? CastHlsSegmentFormat.fromMap(map['hlsSegmentFormat'])
          : null,
      hlsVideoSegmentFormat: map['hlsVideoSegmentFormat'] != null
          ? HlsVideoSegmentFormat.fromMap(map['hlsVideoSegmentFormat'])
          : null,
      startAbsoluteTime: map['startAbsoluteTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startAbsoluteTime'])
          : null,
      textTrackStyle: map['textTrackStyle'] != null
          ? TextTrackStyle.fromMap(map['textTrackStyle'])
          : null,
      tracks: map['tracks'] != null
          ? List<GoogleCastMediaTrack>.from(
              map['tracks']?.map((x) => GoogleCastMediaTrack.fromMap(x)))
          : null,
      userActionStates: map['userActionStates'] != null
          ? List<UserActionState>.from(
              map['userActionStates']?.map((x) => UserActionState.fromMap(x)))
          : null,
      vmapAdsRequest: map['vmapAdsRequest'] != null
          ? VastAdsRequest.fromMap(map['vmapAdsRequest'])
          : null,
    );
  }
}

GoogleCastMediaMetadata? getCastMediaMetadata(Map<String, dynamic> map) {
  return null;
}
