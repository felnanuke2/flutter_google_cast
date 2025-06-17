enum CastMediaStreamType {
  none('NONE'),
  buffered('BUFFERED'),
  live('LIVE');

  final String value;
  const CastMediaStreamType(this.value);
  factory CastMediaStreamType.fromMap(String value) =>
      CastMediaStreamType.values.firstWhere(
        (element) => element.value == value,
        orElse: () => CastMediaStreamType.none,
      );
}
