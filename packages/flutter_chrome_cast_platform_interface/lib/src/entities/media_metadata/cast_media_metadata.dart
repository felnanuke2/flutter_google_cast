import 'package:flutter_chrome_cast_platform_interface/src/common/image.dart';
import 'package:flutter_chrome_cast_platform_interface/src/enums/media_metadata_type.dart';

/// Holds metadata type and images for a media item.
class GoogleCastMediaMetadata {
  /// The type of media metadata.
  final GoogleCastMediaMetadataType metadataType;

  /// List of images associated with the media.
  final List<GoogleCastImage>? images;

  /// Creates a new [GoogleCastMediaMetadata] instance.
  GoogleCastMediaMetadata({required this.metadataType, this.images});
}
