/// Base class for all exceptions thrown by `meeting_place_matrix_livekit`.
///
/// Sealed so callers can exhaustively switch on subtypes:
/// - [MeetingPlaceLiveKitCallMisconfiguredException] — always a programmer
///   error (missing `ProviderScope` override); should not be caught by UI
///   error handlers.
/// - [MeetingPlaceLiveKitCallOperationException] — runtime failure (token
///   fetch, SFU connection, etc.); the UI should surface this gracefully.
sealed class MeetingPlaceLiveKitCallException implements Exception {
  const MeetingPlaceLiveKitCallException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a scoped provider is accessed without the required
/// `ProviderScope` override supplied by `MeetingPlaceLiveKitCallPlugin.scope`.
///
/// This is always a programmer error and should not be caught by the UI.
final class MeetingPlaceLiveKitCallMisconfiguredException
    extends MeetingPlaceLiveKitCallException {
  const MeetingPlaceLiveKitCallMisconfiguredException(super.message);
}

/// Thrown when a LiveKit or token exchange operation fails at runtime.
///
/// The UI should catch this type and surface an appropriate error message.
final class MeetingPlaceLiveKitCallOperationException
    extends MeetingPlaceLiveKitCallException {
  const MeetingPlaceLiveKitCallOperationException(
    super.message, {
    this.innerException,
  });

  final Object? innerException;
}
