import 'dart:convert';

import 'package:google_cast/common/image.dart';
import 'package:google_cast/common/media_metadata/cast_media_metadata.dart';

///Describes a television show episode media artifact.
class CastTvShowMediaMetadata extends CastMediaMetadata {
  CastTvShowMediaMetadata({
    this.seriesTitle,
    this.subtitle,
    this.season,
    this.episode,
    this.images,
    this.originalAirDate,
  }) : super(metadataType: MediaMetadataType.tvShowMediaMetadata);

  ///optional Descriptive title of the t.v. series.
  ///Player can independently retrieve title
  ///using content_id or it can be given
  /// by the sender in the Load message
  final String? seriesTitle;

  /// 	optional Descriptive subtitle of the t.v.
  ///  episode. Player can independently retrieve
  ///  title using content_id or it can be
  ///  given by the sender in the Load message
  final String? subtitle;

  ///optional Season number of the t.v. show
  final int? season;

  ///optional Episode number (in the season) of the t.v. show
  final int? episode;

  ///optional Array of URL(s) to an image associated
  /// with the content. The initial value of the
  /// field can be provided by the sender in
  /// the Load message. Should provide recommended sizes
  final List<CastImage>? images;

  ///optional ISO 8601 date and time
  /// this episode was released. Player
  /// can independently retrieve originalAirDate
  ///  using content_id or it can be given
  ///  by the sender in the Load message
  final DateTime? originalAirDate;

  @override
  Map<String, dynamic> toMap() {
    return {
      'metadataType': metadataType.value,
      'seriesTitle': seriesTitle,
      'subtitle': subtitle,
      'season': season,
      'episode': episode,
      'images': images?.map((x) => x.toMap()).toList(),
      'originalAirDate': originalAirDate?.toIso8601String(),
    };
  }

  factory CastTvShowMediaMetadata.fromMap(Map<String, dynamic> map) {
    return CastTvShowMediaMetadata(
      seriesTitle: map['seriesTitle'],
      subtitle: map['subtitle'],
      season: map['season']?.toInt(),
      episode: map['episode']?.toInt(),
      images: map['images'] != null
          ? List<CastImage>.from(
              map['images']?.map((x) => CastImage.fromMap(x)))
          : null,
      originalAirDate: map['originalAirDate'] != null
          ? DateTime.tryParse(map['originalAirDate'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CastTvShowMediaMetadata.fromJson(String source) =>
      CastTvShowMediaMetadata.fromMap(json.decode(source));
}
