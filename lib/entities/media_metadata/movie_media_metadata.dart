import 'dart:convert';

import 'package:google_cast/common/image.dart';
import 'package:google_cast/enums/media_metadata_type.dart';

import 'cast_media_metadata.dart';

///Describes a movie media artifact.
class GoogleCastMovieMediaMetadata extends GoogleCastMediaMetadata {
  GoogleCastMovieMediaMetadata({
    this.title,
    this.subtitle,
    this.studio,
    super.images,
    this.releaseDate,
  }) : super(
          metadataType: GoogleCastMediaMetadataType.movieMediaMetadata,
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
      'releaseDate': releaseDate?.millisecondsSinceEpoch,
    };
  }

  factory GoogleCastMovieMediaMetadata.fromMap(Map<String, dynamic> map) {
    return GoogleCastMovieMediaMetadata(
      title: map['title'],
      subtitle: map['subtitle'],
      studio: map['studio'],
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'] ?? '')
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleCastMovieMediaMetadata.fromJson(String source) =>
      GoogleCastMovieMediaMetadata.fromMap(json.decode(source));
}
