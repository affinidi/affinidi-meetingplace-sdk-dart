import '../../../meeting_place_core.dart';

class AcceptGroupOfferResult {
  AcceptGroupOfferResult({
    required this.connectionOffer,
    required this.acceptOfferDid,
    required this.permanentChannelDid,
  });
  final GroupConnectionOffer connectionOffer;
  final DidManager acceptOfferDid;
  final DidManager permanentChannelDid;
}
