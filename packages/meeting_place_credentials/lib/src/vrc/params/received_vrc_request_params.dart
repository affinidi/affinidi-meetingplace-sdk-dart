import '../model/vrc_request.dart';

/// Parameters for `MeetingPlaceCredentialsSDK.handleReceivedVrcRequest`.
class ReceivedVrcRequestParams {
  const ReceivedVrcRequestParams({
    required this.permanentChannelDid,
    required this.request,
    required this.hasVrcExchangeInitiated,
    required this.isConnectionInitiator,
    this.issuerDid,
    this.issuerName,
  });

  /// Permanent channel DID of the channel the request was received on.
  final String permanentChannelDid;

  /// The incoming VDIP VRC-issuance request.
  final VrcRequest request;

  /// Whether this device has already initiated a VRC exchange for this
  /// channel.
  final bool hasVrcExchangeInitiated;

  /// Whether the local party initiated the underlying connection.
  final bool isConnectionInitiator;

  /// DID of the local party, used as the issuer if a VRC is issued in
  /// response.
  final String? issuerDid;

  /// Display name of the local party, used as the issuer if a VRC is issued
  /// in response.
  final String? issuerName;
}
