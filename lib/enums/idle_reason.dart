enum GoogleCastMediaIdleReason {
  none,

  /// The media playback completed
  finished,

  /// A sender requested to stop playback using the STOP command
  cancelled,

  /// INTERRUPTED  A sender requested playing a different media using the LOAD command
  interrupted,

  ///ERROR  The media was interrupted due to an error; for example, if the player could not download the media due to network issues
  error;
}
