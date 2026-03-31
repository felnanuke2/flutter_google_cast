import 'package:flutter/material.dart';

import 'package:flutter_chrome_cast_platform_interface/src/common/text_track_font_style.dart';
import 'package:flutter_chrome_cast_platform_interface/src/common/text_track_window_type.dart';

import 'font_generic_family.dart';

///Describes style information for a text track. Colors
///are represented as strings “#RRGGBBAA” where XX are
///the two hexadecimal symbols that represent the
/// 0-255 value for the specific channel/color.
///  It follows CSS 8-digit hex color notation.
///  (See http://dev.w3.org/csswg/css-color/#hex-notation).
class TextTrackStyle {
  ///Background RGBA color, represented as "#RRGGBBAA".
  /// The alpha channel should be used for
  /// transparent backgrounds.

  final Color? backgroundColor;

  ///Custom application data.
  final Map<String, dynamic>? customData;

  ///RGBA color for the edge, represented as
  /// "#RRGGBBAA". This value will be
  ///  ignored if edgeType is NONE.

  /// Edge color for the text track.
  final Color? edgeColor;

  /// Edge type for the text track.
  final TextTrackStyle? edgeType;

  /// If the font is not available in the receiver the fontGenericFamily will be used.

  final String? fontFamily;

  /// Generic font family for the text track.
  final TextTrackFontGenericFamily? fontGenericFamily;

  /// The font scaling factor for the text track (the default is 1.0).
  final int? fontScale;

  /// Font style for the text track.
  final TextTrackFontStyle? fontStyle;

  ///Foreground RGBA color, represented as "#RRGGBBAA".
  final Color? foregroundColor;

  ///RGBA color for the window, represented as
  ///"#RRGGBBAA". This value will be
  ///ignored if windowType is NONE.
  final Color? windowColor;

  ///Rounded corner radius absolute value in pixels (px).
  /// This value will be ignored if windowType
  /// is not ROUNDED_CORNERS.
  final double? windowRoundedCornerRadius;

  ///The window concept is defined in CEA-608 and CEA-708,
  /// See http://goo.gl/M3ea0X. In WebVTT is called a region.

  final TextTrackWindowType? windowType;

  /// Creates a new [TextTrackStyle].
  TextTrackStyle({
    this.backgroundColor,
    this.customData,
    this.edgeColor,
    this.edgeType,
    this.fontFamily,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.foregroundColor,
    this.windowColor,
    this.windowRoundedCornerRadius,
    this.windowType,
  });
}

/// Extension on [Color] to provide hex color functionality.
extension HColor on Color {
  /// Gets the hex color string representation.
  String get hexColor {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0')}';
  }

  /// Creates a [Color] from a hex string.
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
