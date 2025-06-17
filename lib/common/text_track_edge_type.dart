enum TextTrackEdgeType {
  none,
  outline,
  dropShadow,
  raised,
  depressed;

  factory TextTrackEdgeType.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'NONE':
        return TextTrackEdgeType.none;
      case 'OUTLINE':
        return TextTrackEdgeType.outline;
      case 'DROP_SHADOW':
        return TextTrackEdgeType.dropShadow;
      case 'RAISED':
        return TextTrackEdgeType.raised;
      case 'DEPRESSED':
        return TextTrackEdgeType.depressed;
      default:
        throw ArgumentError('Unknown TextTrackEdgeType: $value');
    }
  }
}
