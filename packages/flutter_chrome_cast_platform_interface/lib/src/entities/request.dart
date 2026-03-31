/// Represents a request, including progress, external status, request ID, and error.
class GoogleCastRequest {
  /// Whether the request is in progress.
  final bool inProgress;

  /// Whether the request is external.
  final bool isExternal;

  /// The unique request ID.
  final int requestID;

  /// Error message, if any.
  final String? error;

  /// Creates a new [GoogleCastRequest] instance.
  GoogleCastRequest({
    required this.inProgress,
    required this.isExternal,
    required this.requestID,
    this.error,
  });
}
