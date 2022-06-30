import 'dart:convert';

import 'package:google_cast/common/image.dart';
import 'package:google_cast/enums/media_metadata_type.dart';

import 'cast_media_metadata.dart';

///Describes a television show episode media artifact.
class GoogleCastTvShowMediaMetadata extends GoogleCastMediaMetadata {
  GoogleCastTvShowMediaMetadata({
    this.seriesTitle,
    this.season,
    this.episode,
    super.images,
    this.originalAirDate,
  }) : super(metadataType: GoogleCastMediaMetadataType.tvShowMediaMetadata);

  ///optional Descriptive title of the t.v. series.
  ///Player can independently retrieve title
  ///using content_id or it can be given
  /// by the sender in the Load message
  final String? seriesTitle;

  /// 	optional Descriptive subtitle of the t.v.
  ///  episode. Player can independently retrieve
  ///  title using content_id or it can be
  ///  given by the sender in the Load message

  ///optional Season number of the t.v. show
  final int? season;

  ///optional Episode number (in the season) of the t.v. show
  final int? episode;

  ///optional Array of URL(s) to an image associated
  /// with the content. The initial value of the
  /// field can be provided by the sender in
  /// the Load message. Should provide recommended sizes

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
      'season': season,
      'episode': episode,
      'images': images?.map((x) => x.toMap()).toList(),
      'creationDate': originalAirDate?.millisecondsSinceEpoch,
    };
  }

  factory GoogleCastTvShowMediaMetadata.fromMap(Map<String, dynamic> map) {
    return GoogleCastTvShowMediaMetadata(
      seriesTitle: map['seriesTitle'],
      season: map['season']?.toInt(),
      episode: map['episode']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      originalAirDate: map['originalAirDate'] != null
          ? DateTime.tryParse(map['originalAirDate'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleCastTvShowMediaMetadata.fromJson(String source) =>
      GoogleCastTvShowMediaMetadata.fromMap(json.decode(source));
}
