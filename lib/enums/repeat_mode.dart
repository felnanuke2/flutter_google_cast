///Possible states of queue repeat mode.
enum GoogleCastMediaRepeatMode {
  ///A repeat mode indicating that the repeat mode should be left unchanged.
  unchanged,

  ///Items are played in order, and when the
  /// queue is completed (the last item has ended)
  /// the media session is terminated.
  off,

  ///The current item will be repeated indefinitely.
  single,

  ///The items in the queue will be played
  /// indefinitely. When the last item has
  ///  ended, the first item will be played again.
  all,

  ///The items in the queue will be played indefinitely.
  /// When the last item has ended, the list of items
  /// will be randomly shuffled by the receiver, and
  /// the queue will continue to play starting from the
  /// first item of the shuffled items.
  allAndShuffle;
}
