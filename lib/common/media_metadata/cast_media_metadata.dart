import 'dart:convert';

class CastMediaMetadata {
  final MediaMetadataType metadataType;
  CastMediaMetadata({
    required this.metadataType,
  });

  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
    };
  }

  factory CastMediaMetadata.fromMap(Map<String, dynamic> map) {
    return CastMediaMetadata(
      metadataType: MediaMetadataType.fromMap(map['metadataType']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CastMediaMetadata.fromJson(String source) =>
      CastMediaMetadata.fromMap(json.decode(source));
}

enum MediaMetadataType {
  genericMediaMetadata(0),
  movieMediaMetadata(1),
  tvShowMediaMetadata(2),
  musicTrackMediaMetadata(3),
  photoMediaMetadata(4);

  final int value;
  const MediaMetadataType(this.value);

  factory MediaMetadataType.fromMap(int value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse: () => genericMediaMetadata,
    );
  }
}
