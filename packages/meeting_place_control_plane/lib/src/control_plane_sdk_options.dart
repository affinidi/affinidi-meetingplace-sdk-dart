/// Control Plane SDK configuration settings.
class ControlPlaneSDKOptions {
  const ControlPlaneSDKOptions({
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 2000),
    this.connectTimeout = const Duration(milliseconds: 30000),
    this.receiveTimeout = const Duration(milliseconds: 30000),
    this.idleTimeout = const Duration(seconds: 3),
  });

  /// The number of retry attempts for a request when a network issue occurs.
  /// If a request fails due to a network error, it will be retried up to this
  /// number of times before ultimately failing.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;

  /// Specifies the maximum time (in milliseconds) the SDK will wait while
  /// establishing a connection to the server. If the connection cannot be
  /// established within this time, the request will be aborted and a timeout
  /// error will be thrown.
  final Duration connectTimeout;

  /// Defines the maximum duration (in milliseconds) the SDK will wait to
  /// receive a response after a connection has been successfully established.
  /// If no data is received within this time frame, the request will be
  /// aborted and a timeout error will be triggered.
  final Duration receiveTimeout;

  /// The maximum duration an idle HTTP keep-alive connection is kept open
  /// before being closed and removed from the connection pool.
  ///
  /// Defaults to 3 seconds to match Dio's native adapter behavior.
  /// Override it when a deployment benefits from longer keep-alive reuse.
  final Duration idleTimeout;
}
