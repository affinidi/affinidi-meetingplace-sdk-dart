import '../entity/connection_offer.dart';

abstract interface class ConnectionOfferRepository {
  Future<ConnectionOffer?> getConnectionOfferByOfferLink(String offerLink);
  Future<ConnectionOffer?> getConnectionOfferByPermanentChannelDid(
    String permanentChannelDid,
  );
  Future<ConnectionOffer?> getConnectionOfferByGroupDid(String groupDid);

  Future<List<ConnectionOffer>> listConnectionOffers();

  Future<void> createConnectionOffer(ConnectionOffer connectionOffer);
  Future<void> updateConnectionOffer(ConnectionOffer connectionOffer);
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer);

  Future<List<ConnectionOffer>> getPublishedOffersByExternalRef(
    String externalRef,
  );
}
