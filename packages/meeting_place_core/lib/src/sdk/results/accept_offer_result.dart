import '../../../meeting_place_core.dart';

class AcceptOfferResult<T extends ConnectionOffer> {
  AcceptOfferResult({
    required this.connectionOffer,
    required this.acceptOfferDidManager,
    required this.permanentChannelDidManager,
  });
  final T connectionOffer;
  final DidManager acceptOfferDidManager;
  final DidManager permanentChannelDidManager;
}
