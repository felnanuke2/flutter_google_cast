///Possible states of queue repeat mode.
enum QueueRepeatMode {
  ///Items are played in order, and when the
  /// queue is completed (the last item has ended)
  /// the media session is terminated.
  OFF,

  ///The items in the queue will be played
  /// indefinitely. When the last item has
  ///  ended, the first item will be played again.
  ALL,

  ///The current item will be repeated indefinitely.
  SINGLE,

  ///The items in the queue will be played indefinitely.
  /// When the last item has ended, the list of items
  /// will be randomly shuffled by the receiver, and
  /// the queue will continue to play starting from the
  /// first item of the shuffled items.

  ALL_AND_SHUFFLE;

  static QueueRepeatMode fromMap(String? map) {
    switch (map) {
      case 'OFF':
        return QueueRepeatMode.OFF;
      case 'ALL':
        return QueueRepeatMode.ALL;
      case 'SINGLE':
        return QueueRepeatMode.SINGLE;
      case 'ALL_AND_SHUFFLE':
        return QueueRepeatMode.ALL_AND_SHUFFLE;
      default:
        return QueueRepeatMode.OFF;
    }
  }
}
