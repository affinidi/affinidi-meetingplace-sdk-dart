class MatrixSubscriptionOptions {
  /// Creates a new [MatrixSubscriptionOptions] instance.
  const MatrixSubscriptionOptions({
    this.excludeSelf = false,
    this.otherPartyDid,
  });

  /// If true, the SDK will not emit events for messages sent by the user
  /// themselves.
  final bool excludeSelf;

  /// When set, the subscription also emits `m.presence` events for this DID.
  final String? otherPartyDid;
}
