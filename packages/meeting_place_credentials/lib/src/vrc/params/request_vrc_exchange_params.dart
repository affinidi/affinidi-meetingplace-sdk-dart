/// Parameters for `MeetingPlaceCredentialsSDK.requestVrcExchange`.
class RequestVrcExchangeParams {
  const RequestVrcExchangeParams({
    required this.channelDid,
    required this.requesterDid,
    required this.requesterName,
  });

  /// The DID of the channel the VRC exchange request is sent over.
  final String channelDid;

  /// The DID of the party requesting the VRC exchange.
  final String requesterDid;

  /// The display name of the party requesting the VRC exchange.
  final String requesterName;
}
