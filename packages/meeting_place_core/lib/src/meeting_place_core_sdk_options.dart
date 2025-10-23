class MeetingPlaceCoreSDKOptions {
  const MeetingPlaceCoreSDKOptions({
    this.secondsBeforeExpiryReauthenticate = 60,
    this.debounceControlPlaneEvents = const Duration(milliseconds: 200),
    this.didResolverAddress,
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 2000),
    this.connectTimeout = const Duration(milliseconds: 30000),
    this.receiveTimeout = const Duration(milliseconds: 30000),
  });

  /// Number of seconds before the access token is refreshed to ensure
  /// continued access to the mediator instance.
  final int secondsBeforeExpiryReauthenticate;

  /// Number of miliseconds to wait before processing discovery events.
  /// This debounce mechanism is used to let multiple events settle and process
  /// them at once.
  final Duration debounceControlPlaneEvents;

  /// Specifies the custom address utilized by the DID resolver service.
  final String? didResolverAddress;

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
}
