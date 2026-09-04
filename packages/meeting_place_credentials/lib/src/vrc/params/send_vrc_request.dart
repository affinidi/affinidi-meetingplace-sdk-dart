/// Parameters for `MeetingPlaceCredentialsSDK.sendVrc`.
class SendVrcRequest {
  const SendVrcRequest({
    required this.channelDid,
    required this.issuerDid,
    required this.issuerName,
    required this.peerDid,
    required this.peerName,
  });

  /// The DID of the channel the VRC is sent over.
  final String channelDid;

  /// The DID of the party issuing the VRC.
  final String issuerDid;

  /// The display name of the party issuing the VRC.
  final String issuerName;

  /// The DID of the party the VRC is issued to.
  final String peerDid;

  /// The display name of the party the VRC is issued to.
  final String peerName;
}
