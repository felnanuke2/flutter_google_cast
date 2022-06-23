class AFlutterGoogleCastOptions {
  final bool physicalVolumeButtonsWillControlDeviceVolume;
  final bool disableDiscoveryAutostart;
  final bool disableAnalyticsLogging;
  final bool suspendSessionsWhenBackgrounded;
  final bool stopReceiverApplicationWhenEndingSession;
  final bool startDiscoveryAfterFirstTapOnCastButton;
  AFlutterGoogleCastOptions({
    this.physicalVolumeButtonsWillControlDeviceVolume = true,
    this.disableDiscoveryAutostart = false,
    this.disableAnalyticsLogging = false,
    this.suspendSessionsWhenBackgrounded = true,
    this.stopReceiverApplicationWhenEndingSession = false,
    this.startDiscoveryAfterFirstTapOnCastButton = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'physicalVolumeButtonsWillControlDeviceVolume':
          physicalVolumeButtonsWillControlDeviceVolume,
      'disableDiscoveryAutostart': disableDiscoveryAutostart,
      'disableAnalyticsLogging': disableAnalyticsLogging,
      'suspendSessionsWhenBackgrounded': suspendSessionsWhenBackgrounded,
      'stopReceiverApplicationWhenEndingSession':
          stopReceiverApplicationWhenEndingSession,
      'startDiscoveryAfterFirstTapOnCastButton':
          startDiscoveryAfterFirstTapOnCastButton,
    };
  }
}
