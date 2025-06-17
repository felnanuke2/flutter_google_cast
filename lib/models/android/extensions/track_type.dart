import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastTrackTypeAndroid on TrackType {
  static TrackType fromMap(String value) {
    return TrackType.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TrackType.unknown,
    );
  }
}
