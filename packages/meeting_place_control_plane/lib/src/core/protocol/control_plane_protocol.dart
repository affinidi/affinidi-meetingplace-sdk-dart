enum ControlPlaneProtocol {
  meetingplaceAuthChallenge(
    'https://affinidi.io/meetingplace/1.0/authenticate/challenge',
  );

  const ControlPlaneProtocol(this.value);
  final String value;
}
