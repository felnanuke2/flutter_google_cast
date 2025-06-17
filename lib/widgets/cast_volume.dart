import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager.dart';
import 'package:get/get_rx/get_rx.dart';

class GoogleCastVolume extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;
  final Color? popupBackgroundColor;
  final Color? sliderActiveColor;
  final Color? sliderInactiveColor;
  final Color? sliderThumbColor;
  
  const GoogleCastVolume({
    super.key,
    this.iconColor,
    this.iconSize,
    this.popupBackgroundColor,
    this.sliderActiveColor,
    this.sliderInactiveColor,
    this.sliderThumbColor,
  });

  @override
  State<GoogleCastVolume> createState() => _GoogleCastVolumeState();
}

class _GoogleCastVolumeState extends State<GoogleCastVolume> {
  @override
  void initState() {
    GoogleCastSessionManager.instance.currentSessionStream.listen((event) {
      volumeLevel.value = event?.currentDeviceVolume ?? 0;
      volumeMuted.value = event?.currentDeviceMuted ?? false;
    });
    super.initState();
  }

  final volumeLevel = 0.5.obs;
  final volumeMuted = false.obs;
  bool isSliderTapDown = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: widget.popupBackgroundColor,
      icon: StreamBuilder(
          stream: volumeMuted.stream,
          builder: (context, snapshot) {
            return Icon(
              volumeMuted.value || volumeLevel.value == 0
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: widget.iconColor ?? Colors.white,
              size: widget.iconSize ?? 44,
            );
          }),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            enabled: false,
            child: StreamBuilder(
              stream: volumeLevel.stream,
              builder: (context, snapshot) {
                return Slider(
                  value: volumeLevel.value,
                  onChanged: _onVolumeChanged,
                  onChangeStart: _onVolumeChangedStart,
                  onChangeEnd: _onVolumeChangedEnd,
                  activeColor: widget.sliderActiveColor,
                  inactiveColor: widget.sliderInactiveColor,
                  thumbColor: widget.sliderThumbColor,
                );
              },
            ),
          ),
        ];
      },
    );
  }

  void _onVolumeChangedEnd(double value) {
    isSliderTapDown = false;
    GoogleCastSessionManager.instance.setDeviceVolume(value);
  }

  void _onVolumeChangedStart(double value) {
    isSliderTapDown = true;
  }

  void _onVolumeChanged(double value) {
    volumeLevel.value = value;
  }
}
