/// DIDComm message type URIs used by the control plane's authentication
/// protocol.
enum ControlPlaneProtocol {
  /// The message type for an authentication request.
  authenticate(
    'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate',
  ),

  /// The message type for an authentication challenge, as used by
  /// `MeetingplaceAuthChallenge`.
  authChallenge(
    'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate/challenge',
  );

  const ControlPlaneProtocol(this.value);

  /// The wire string representation of this protocol message type.
  final String value;
}
