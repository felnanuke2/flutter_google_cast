import 'package:flutter/cupertino.dart';

/// Theme data for customizing the ExpandedGoogleCastPlayerController widget.
class GoogleCastPlayerTheme {
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final TextStyle? titleTextStyle;
  final TextStyle? deviceTextStyle;
  final TextStyle? timeTextStyle;
  final Color? iconColor;
  final Color? disabledIconColor;
  final double? iconSize;
  final Widget? backgroundWidget;
  final BorderRadius? imageBorderRadius;
  final List<BoxShadow>? imageShadow;
  final double? imageMaxWidth;
  final double? imageMaxHeight;
  final BoxFit? imageFit;
  final Widget? noImageFallback;

  /// Background color for popup menus (like captions menu)
  final Color? popupBackgroundColor;

  /// Text color for popup menu items
  final Color? popupTextColor;

  /// Text style for popup menu items
  final TextStyle? popupTextStyle;

  /// Volume slider active color
  final Color? volumeSliderActiveColor;

  /// Volume slider inactive color
  final Color? volumeSliderInactiveColor;

  /// Volume slider thumb color
  final Color? volumeSliderThumbColor;

  const GoogleCastPlayerTheme({
    this.backgroundColor,
    this.backgroundGradient,
    this.titleTextStyle,
    this.deviceTextStyle,
    this.timeTextStyle,
    this.iconColor,
    this.disabledIconColor,
    this.iconSize,
    this.backgroundWidget,
    this.imageBorderRadius,
    this.imageShadow,
    this.imageMaxWidth,
    this.imageMaxHeight,
    this.imageFit,
    this.noImageFallback,
    this.popupBackgroundColor,
    this.popupTextColor,
    this.popupTextStyle,
    this.volumeSliderActiveColor,
    this.volumeSliderInactiveColor,
    this.volumeSliderThumbColor,
  });
}
