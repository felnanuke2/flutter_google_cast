/// A text message received from a custom Google Cast namespace.
class GoogleCastMessage {
  /// Creates a custom Cast message.
  const GoogleCastMessage({required this.namespace, required this.message});

  /// The Cast namespace that delivered the message.
  final String namespace;

  /// The UTF-8 text payload delivered by the receiver.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleCastMessage &&
          namespace == other.namespace &&
          message == other.message;

  @override
  int get hashCode => Object.hash(namespace, message);
}
