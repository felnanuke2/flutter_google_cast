import 'package:flutter_chrome_cast/lib.dart';

/// iOS-specific implementation of generic media metadata.
class GoogleCastGenericMediaMetadataIOS extends GoogleCastGenericMediaMetadata {
  /// Creates an iOS generic media metadata instance.
  GoogleCastGenericMediaMetadataIOS({
    required super.title,
    required super.subtitle,
    required super.images,
    super.releaseDate,
  });

  /// Creates a generic media metadata instance from a map.
  factory GoogleCastGenericMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastGenericMediaMetadataIOS(
      title: map['title'],
      subtitle: map['subtitle'],
      images: map['images'] != null
          ? List<GoogleCastImage>.from(map['images']?.map(
              (x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x))))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['releaseDate'] ?? 0)
          : null,
    );
  }
}
