/// A class that defines the configuration for retrying failed HTTP requests.
class RetryConfig {
  /// Creates a new [RetryConfig] instance.
  ///
  /// This sets the maxRetries to 5 while maxDelay is set to 2 seconds.
  const RetryConfig({
    this.maxRetries = 5,
    this.maxDelay = const Duration(seconds: 2),
  });
  final int maxRetries;
  final Duration maxDelay;
}
