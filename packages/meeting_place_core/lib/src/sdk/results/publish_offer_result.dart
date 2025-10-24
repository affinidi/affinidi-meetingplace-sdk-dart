import 'package:ssi/ssi.dart';

import '../../entity/connection_offer.dart';

class PublishOfferResult<T extends ConnectionOffer> {
  PublishOfferResult({
    required this.connectionOffer,
    required this.publishedOfferDidManager,
    this.groupOwnerDidManager,
  });

  /// Connection offer represents published offer
  final T connectionOffer;

  /// DidManager representing DID used to publish offer
  final DidManager publishedOfferDidManager;

  /// DidManager representing DID of group owner.
  /// Is only returned if connection offer is of type GroupConnectionOffer
  final DidManager? groupOwnerDidManager;
}
