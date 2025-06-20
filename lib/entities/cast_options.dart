/// Configuration options for Google Cast functionality.
class GoogleCastOptions {
  /// Whether physical volume buttons will control device volume.
  final bool physicalVolumeButtonsWillControlDeviceVolume;

  /// Whether to disable discovery autostart.
  final bool disableDiscoveryAutostart;

  /// Whether to disable analytics logging.
  final bool disableAnalyticsLogging;

  /// Whether to suspend sessions when backgrounded.
  final bool suspendSessionsWhenBackgrounded;

  /// Whether to stop receiver application when ending session.
  final bool stopReceiverApplicationWhenEndingSession;

  /// Whether to start discovery after first tap on cast button.
  final bool startDiscoveryAfterFirstTapOnCastButton;

  /// Creates a new [GoogleCastOptions] instance.
  GoogleCastOptions({
    this.physicalVolumeButtonsWillControlDeviceVolume = true,
    this.disableDiscoveryAutostart = false,
    this.disableAnalyticsLogging = false,
    this.suspendSessionsWhenBackgrounded = true,
    this.stopReceiverApplicationWhenEndingSession = false,
    this.startDiscoveryAfterFirstTapOnCastButton = true,
  });

  /// Converts this options object to a map representation.
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
