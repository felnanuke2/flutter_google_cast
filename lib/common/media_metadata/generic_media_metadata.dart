import 'dart:convert';

import 'package:google_cast/common/image.dart';
import 'package:google_cast/common/image.dart';

import 'cast_media_metadata.dart';

///Describes a generic media artifact.
class CastGenericMediaMetadata extends CastMediaMetadata {
  ///optional Descriptive title of the content.
  /// Player can independently retrieve title
  /// using content_id or it can be given by
  ///  the sender in the Load message
  final String? title;

  /// 	optional Descriptive subtitle of the content.
  /// Player can independently retrieve title using
  /// content_id or it can be given by the sender
  /// in the Load message
  final String? subtitle;

  ///optional Array of URL(s) to an image associated with the content.
  ///The initial value of the field can be provided by the sender in the
  ///Load message. Should provide recommended sizes
  final List<CastImage>? images;

  ///optional ISO 8601 date and time
  /// this content was released. Player can
  ///  independently retrieve title using
  ///  content_id or it can be given
  ///  by the sender in the Load message
  final DateTime? releaseDate;

  CastGenericMediaMetadata({
    required super.metadataType,
    this.title,
    this.subtitle,
    this.images,
    this.releaseDate,
  });
  @override
  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
      'title': title,
      'subtitle': subtitle,
      'images': images?.map((x) => x.toMap()).toList(),
      'releaseDate': releaseDate?.toIso8601String(),
    };
  }

  factory CastGenericMediaMetadata.fromMap(Map<String, dynamic> map) {
    return CastGenericMediaMetadata(
      metadataType: MediaMetadataType.fromMap(map['metadataType']),
      title: map['title'],
      subtitle: map['subtitle'],
      images: map['images'] != null
          ? List<CastImage>.from(
              map['images']?.map((x) => CastImage.fromMap(x)))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'] ?? '')
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CastGenericMediaMetadata.fromJson(String source) =>
      CastGenericMediaMetadata.fromMap(json.decode(source));
}
