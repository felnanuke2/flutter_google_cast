///Possible text track window types.
enum TextTrackWindowType {
  none,
  normal,
  roundedCorners;

  factory TextTrackWindowType.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'NONE':
        return TextTrackWindowType.none;
      case 'NORMAL':
        return TextTrackWindowType.normal;
      case 'ROUNDED_CORNERS':
        return TextTrackWindowType.roundedCorners;
      default:
        throw ArgumentError('Unknown TextTrackWindowType: $value');
    }
  }
}
