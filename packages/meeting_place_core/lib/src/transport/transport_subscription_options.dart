import '../../meeting_place_core.dart' show MeetingPlaceTransport;

/// Options controlling the behaviour of a [MeetingPlaceTransport.subscribe]
/// call.
class TransportSubscriptionOptions {
  const TransportSubscriptionOptions({
    this.excludeSelf = false,
    this.syncGracePeriodDuration,
    this.keepSyncActiveOnEnd = false,
  });

  /// When true, events sent by the local client are not re-emitted by the
  /// subscription stream.
  final bool excludeSelf;

  /// How long to keep the background sync running after the last subscription
  /// for this options instance ends. Null disables sync immediately.
  final Duration? syncGracePeriodDuration;

  /// When true, background sync is never automatically disabled after the
  /// subscription ends — regardless of [syncGracePeriodDuration].
  final bool keepSyncActiveOnEnd;
}
