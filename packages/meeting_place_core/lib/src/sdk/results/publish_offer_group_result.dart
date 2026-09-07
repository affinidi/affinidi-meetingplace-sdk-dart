import 'package:ssi/ssi.dart';

import '../../entity/group_connection_offer.dart';

/// The result of publishing a group connection offer.
class PublishOfferGroupResult {
  /// Creates a [PublishOfferGroupResult].
  PublishOfferGroupResult({
    required this.connectionOffer,
    required this.publishedOfferDidManager,
    required this.groupDidManager,
    required this.groupOwnerDidManager,
  });

  /// The published group connection offer.
  final GroupConnectionOffer connectionOffer;

  /// The DID manager for the DID used to publish the offer.
  final DidManager publishedOfferDidManager;

  /// The DID manager for the group's DID.
  final DidManager groupDidManager;

  /// The DID manager for the group owner's DID.
  final DidManager groupOwnerDidManager;
}
