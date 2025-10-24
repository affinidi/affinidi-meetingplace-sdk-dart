import '../../../meeting_place_core.dart';

class AcceptOfferResult {
  AcceptOfferResult({
    required this.connectionOffer,
    required this.channel,
    required this.acceptOfferDid,
    required this.permanentChannelDid,
  });

  final ConnectionOffer connectionOffer;
  final Channel channel;
  final DidManager acceptOfferDid;
  final DidManager permanentChannelDid;
}
