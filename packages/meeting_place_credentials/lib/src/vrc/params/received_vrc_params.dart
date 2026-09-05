import '../model/vrc_exchange_state.dart';

/// Parameters for `MeetingPlaceCredentialsSDK.handleReceivedVrc`.
class ReceivedVrcParams {
  const ReceivedVrcParams({
    required this.permanentChannelDid,
    required this.vcBlob,
    required this.exchangeState,
    this.issuerDid,
    this.issuerName,
  });

  /// Permanent channel DID of the channel the VRC was received on.
  final String permanentChannelDid;

  /// The raw serialised VC JSON string of the received VRC.
  final String vcBlob;

  /// Current state of the VRC exchange for this channel.
  final VrcExchangeState exchangeState;

  /// DID of the local party, used as the issuer if the local party
  /// reciprocates with its own VRC.
  final String? issuerDid;

  /// Display name of the local party, used as the issuer if the local party
  /// reciprocates with its own VRC.
  final String? issuerName;
}
