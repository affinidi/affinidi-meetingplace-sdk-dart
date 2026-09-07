/// The mediator and control-plane DIDs a `MeetingPlaceCoreSDK` instance is
/// configured to use.
class MeetingPlaceCoreConfig {
  /// Creates a [MeetingPlaceCoreConfig].
  const MeetingPlaceCoreConfig({
    required this.mediatorDid,
    required this.controlPlaneDid,
  });

  /// DID of the default mediator used for DIDComm messaging.
  final String mediatorDid;

  /// DID of the control plane service.
  final String controlPlaneDid;
}
