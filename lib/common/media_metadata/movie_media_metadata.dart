import 'dart:convert';

import 'package:google_cast/common/image.dart';
import 'package:google_cast/common/media_metadata/cast_media_metadata.dart';

///Describes a movie media artifact.
class CastMovieMediaMetadata extends CastMediaMetadata {
  CastMovieMediaMetadata({
    this.title,
    this.subtitle,
    this.studio,
    this.images,
    this.releaseDate,
  }) : super(
          metadataType: MediaMetadataType.movieMediaMetadata,
        );

  /// 	optional Descriptive title
  ///  of the content. Player can
  ///  independently retrieve title using
  ///  content_id or it can be given by
  ///  the sender in the Load message
  final String? title;

  ///optional Descriptive subtitle
  /// of the content. Player can
  /// independently retrieve title
  /// using content_id or it can be
  ///  given by the sender in
  /// the Load message
  final String? subtitle;

  ///optional Studio which released the content.
  /// Player can independently retrieve studio
  ///  using content_id or it can be given by
  ///  the sender in the Load message
  final String? studio;

  /// 	optional Array of URL(s) to an image associated
  /// with the content. The initial value of the field
  /// can be provided by the sender in the Load message.
  ///  Should provide recommended sizes
  final List<CastImage>? images;

  ///optional ISO 8601 date and time this content
  ///was released. Player can independently retrieve
  ///title using content_id or it can be given by the
  /// sender in the Load message
  final DateTime? releaseDate;

  @override
  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
      'title': title,
      'subtitle': subtitle,
      'studio': studio,
      'images': images?.map((x) => x.toMap()).toList(),
      'releaseDate': releaseDate?.toIso8601String(),
    };
  }

  factory CastMovieMediaMetadata.fromMap(Map<String, dynamic> map) {
    return CastMovieMediaMetadata(
      title: map['title'],
      subtitle: map['subtitle'],
      studio: map['studio'],
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

  factory CastMovieMediaMetadata.fromJson(String source) =>
      CastMovieMediaMetadata.fromMap(json.decode(source));
}
