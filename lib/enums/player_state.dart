enum CastMediaPlayerState {
  ///IDLE  Player has not been loaded yet
  idle('IDLE'),

  ///Player is actively playing content
  playing('PLAYING'),

  ///Player is paused
  paused('PAUSED'),

  ///Player is in PLAY mode but not actively
  /// playing content (currentTime is not changing)
  buffering('BUFFERING'),
  unknown('UNKNOWN');

  final String rawValue;
  const CastMediaPlayerState(this.rawValue);

  factory CastMediaPlayerState.fromMap(String value) {
    return CastMediaPlayerState.values.firstWhere(
      (element) => element.rawValue == value,
      orElse: () => CastMediaPlayerState.unknown,
    );
  }
}
