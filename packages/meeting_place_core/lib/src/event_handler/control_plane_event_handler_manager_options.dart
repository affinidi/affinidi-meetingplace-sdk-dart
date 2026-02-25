class ControlPlaneEventHandlerManagerOptions {
  const ControlPlaneEventHandlerManagerOptions({
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 5000),
    this.messageTypesForSequenceTracking = const [
      'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/message',
    ],
  });

  /// The number of retry attempts for a request when a network issue occurs.
  /// If a request fails due to a network error, it will be retried up to this
  /// number of times before ultimately failing.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;

  /// The list of message types that are considered relevant for chat activity.
  /// When processing channel activity events, only messages with these types
  /// will be considered for updating the channel's message synchronization
  /// marker and sequence number.
  final List<String> messageTypesForSequenceTracking;
}
