class ControlPlaneEventHandlerManagerOptions {
  const ControlPlaneEventHandlerManagerOptions({
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 5000),
  });

  /// The number of retry attempts for a request when a network issue occurs.
  /// If a request fails due to a network error, it will be retried up to this
  /// number of times before ultimately failing.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;
}
