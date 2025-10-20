class MeetingPlaceCoreSDKOptions {
  const MeetingPlaceCoreSDKOptions({
    this.secondsBeforeExpiryReauthenticate = 60,
    this.debounceDiscoveryEventsInMilliseconds = 200,
    this.didResolverAddress,
  });

  /// Number of seconds before the access token is refreshed to ensure
  /// continued access to the mediator instance.
  final int secondsBeforeExpiryReauthenticate;

  /// Number of miliseconds to wait before processing discovery events.
  /// This debounce mechanism is used to let multiple events settle and process
  /// them at once.
  final int debounceDiscoveryEventsInMilliseconds;

  /// Specifies the custom address utilized by the DID resolver service.
  final String? didResolverAddress;
}
