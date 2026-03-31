/// Value object that represents Cast device volume.
class CastDeviceVolume {
  /// Creates a valid [CastDeviceVolume] between 0.0 and 1.0.
  const CastDeviceVolume(this.value, {this.muted = false})
      : assert(value >= 0 && value <= 1, 'value must be between 0 and 1');

  /// Device volume level in the inclusive range [0.0, 1.0].
  final double value;

  /// Whether the device is muted.
  final bool muted;

  /// Creates a new instance preserving current values unless overridden.
  CastDeviceVolume copyWith({double? value, bool? muted}) {
    return CastDeviceVolume(
      (value ?? this.value).clamp(0, 1),
      muted: muted ?? this.muted,
    );
  }

  /// Returns a new instance with volume increased by [percent] points.
  ///
  /// Example: 10 increases volume by 0.10.
  CastDeviceVolume increaseByPercent(double percent) {
    assert(percent >= 0, 'percent must be non-negative');
    final delta = percent / 100;
    return copyWith(value: value + delta);
  }

  /// Returns a new instance with volume decreased by [percent] points.
  ///
  /// Example: 10 decreases volume by 0.10.
  CastDeviceVolume decreaseByPercent(double percent) {
    assert(percent >= 0, 'percent must be non-negative');
    final delta = percent / 100;
    return copyWith(value: value - delta);
  }

  /// Returns a muted copy.
  CastDeviceVolume mute() => copyWith(muted: true);

  /// Returns an unmuted copy.
  CastDeviceVolume unmute() => copyWith(muted: false);

  /// Returns a copy with mute state toggled.
  CastDeviceVolume toggleMute() => copyWith(muted: !muted);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CastDeviceVolume &&
        other.value == value &&
        other.muted == muted;
  }

  @override
  int get hashCode => Object.hash(value, muted);
}
