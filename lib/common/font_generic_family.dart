enum TextTrackFontGenericFamily {
  sansSerif,
  monospacedSansSerif,
  serif,
  monospacedSerif,
  casual,
  cursive,
  smallCapitals;

  factory TextTrackFontGenericFamily.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'SANS_SERIF':
        return TextTrackFontGenericFamily.sansSerif;
      case 'MONOSPACED_SANS_SERIF':
        return TextTrackFontGenericFamily.monospacedSansSerif;
      case 'SERIF':
        return TextTrackFontGenericFamily.serif;
      case 'MONOSPACED_SERIF':
        return TextTrackFontGenericFamily.monospacedSerif;
      case 'CASUAL':
        return TextTrackFontGenericFamily.casual;
      case 'CURSIVE':
        return TextTrackFontGenericFamily.cursive;
      case 'SMALL_CAPITALS':
        return TextTrackFontGenericFamily.smallCapitals;
      default:
        throw ArgumentError('Unknown TextTrackFontGenericFamily: $value');
    }
  }
}
