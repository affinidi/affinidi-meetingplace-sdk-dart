import '../../../meeting_place_core.dart';

class AcceptGroupOfferResult {
  AcceptGroupOfferResult({
    required this.connectionOffer,
    required this.acceptOfferDidManager,
    required this.permanentChannelDidManager,
  });
  final GroupConnectionOffer connectionOffer;
  final DidManager acceptOfferDidManager;
  final DidManager permanentChannelDidManager;
}
