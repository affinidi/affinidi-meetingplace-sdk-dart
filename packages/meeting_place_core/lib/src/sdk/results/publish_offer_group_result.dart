import 'package:ssi/ssi.dart';

import '../../entity/group_connection_offer.dart';

class PublishOfferGroupResult {
  PublishOfferGroupResult({
    required this.connectionOffer,
    required this.publishedOfferDidManager,
    required this.groupDidManager,
    required this.groupOwnerDidManager,
  });
  final GroupConnectionOffer connectionOffer;
  final DidManager publishedOfferDidManager;
  final DidManager groupDidManager;
  final DidManager groupOwnerDidManager;
}
