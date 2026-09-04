import '../../../meeting_place_core.dart';

class AcceptOfferResult {
  AcceptOfferResult({
    required this.connectionOffer,
    required this.channel,
    required this.acceptOfferDidManager,
    required this.permanentChannelDidManager,
  });

  final ConnectionOffer connectionOffer;
  final Channel channel;
  final DidManager acceptOfferDidManager;
  final DidManager permanentChannelDidManager;
}
