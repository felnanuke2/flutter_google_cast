enum TrackType {
  AUDIO,
  VIDEO,
  TEXT;

  factory TrackType.fromMap(String value) {
    return values.firstWhere((element) => element.toString() == value);
  }

  @override
  String toString() {
    return name;
  }
}
