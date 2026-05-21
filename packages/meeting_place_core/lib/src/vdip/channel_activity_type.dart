/// String constants for the `type` field used in Control Plane
/// `ChannelActivity` notifications related to VDIP message delivery.
abstract final class ChannelActivityType {
  static const String vdipRequestIssuance = 'vdip-request-issuance';
  static const String vdipIssuedCredentials = 'vdip-issued-credentials';
}
