/// Parameters for `MeetingPlaceCoreSDK.registerForDIDCommNotifications`.
class RegisterForDidcommNotificationsRequest {
  const RegisterForDidcommNotificationsRequest({
    this.mediatorDid,
    this.recipientDid,
  });

  /// The specific Mediator DID to register with. If not provided, the
  /// default SDK Mediator DID will be used.
  final String? mediatorDid;

  /// An existing DID to use as the notification recipient. If not provided,
  /// a new DID will be generated.
  final String? recipientDid;
}
