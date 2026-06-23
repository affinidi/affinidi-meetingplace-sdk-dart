class MatrixSubscriptionOptions {
  /// Creates a new [MatrixSubscriptionOptions] instance.
  const MatrixSubscriptionOptions({
    this.excludeSelf = false,
    this.syncGracePeriodDuration,
    this.keepSyncActiveOnEnd = false,
  });

  /// If true, the SDK will not emit events for messages sent by the user
  /// themselves.
  final bool excludeSelf;

  /// How long to keep background sync running after the last subscription
  /// for this options instance ends.
  ///
  /// - `null` (default): background sync is disabled immediately when the last
  ///   subscription ends.
  /// - A positive [Duration]: sync stays active for that duration before being
  ///   disabled. Useful for short gaps between successive chat sessions so the
  ///   sync loop does not needlessly stop and restart.
  ///
  /// Ignored when [keepSyncActiveOnEnd] is `true`.
  final Duration? syncGracePeriodDuration;

  /// When `true`, background sync is never automatically disabled after the
  /// subscription ends — regardless of [syncGracePeriodDuration].
  ///
  /// Use this for clients that should stay connected indefinitely (e.g. a
  /// background notification listener). The caller is responsible for
  /// stopping sync.
  final bool keepSyncActiveOnEnd;
}
