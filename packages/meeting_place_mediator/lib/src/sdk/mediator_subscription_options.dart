class MediatorSubscriptionOptions {
  const MediatorSubscriptionOptions({
    this.deleteMessageDelay = const Duration(milliseconds: 3000),
  });

  /// Delay before deleting messages from the mediator after they have been
  /// processed by listeners on the WebSocket connection.
  final Duration deleteMessageDelay;
}
