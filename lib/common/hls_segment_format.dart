///Format of an HLS audio segment.
enum CastHlsSegmentFormat {
  aac,
  ac3,
  mp3,
  ts,
  tsAac,
  eAc3,
  fmp4,
  none;

  factory CastHlsSegmentFormat.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'AAC':
        return CastHlsSegmentFormat.aac;
      case 'AC3':
        return CastHlsSegmentFormat.ac3;
      case 'MP3':
        return CastHlsSegmentFormat.mp3;
      case 'TS':
        return CastHlsSegmentFormat.ts;
      case 'TS_AAC':
        return CastHlsSegmentFormat.tsAac;
      case 'E_AC3':
        return CastHlsSegmentFormat.eAc3;
      case 'FMP4':
        return CastHlsSegmentFormat.fmp4;
      case 'NONE':
        return CastHlsSegmentFormat.none;
      default:
        return CastHlsSegmentFormat.none;
    }
  }
}
