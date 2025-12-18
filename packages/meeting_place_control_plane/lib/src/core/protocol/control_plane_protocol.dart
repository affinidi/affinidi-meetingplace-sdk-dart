enum ControlPlaneProtocol {
  authenticate(
    'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate',
  ),

  authChallenge(
    'https://affinidi.com/didcomm/protocols/meeting-place-control-plane/1.0/authenticate/challenge',
  );

  const ControlPlaneProtocol(this.value);
  final String value;
}
