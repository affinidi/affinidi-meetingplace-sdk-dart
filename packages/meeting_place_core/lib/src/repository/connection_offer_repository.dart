import '../entity/connection_offer.dart';

abstract interface class ConnectionOfferRepository {
  Future<ConnectionOffer?> findConnectionOfferByOfferLink(String offerLink);
  Future<ConnectionOffer?> findConnectionOfferByPermanentChannelDid(
    String permanentChannelDid,
  );
  Future<ConnectionOffer?> findConnectionOfferByGroupDid(String groupDid);

  Future<List<ConnectionOffer>> listConnectionOffers();

  Future<void> createConnectionOffer(ConnectionOffer connectionOffer);
  Future<void> updateConnectionOffer(ConnectionOffer connectionOffer);
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer);

  Future<List<ConnectionOffer>> getConnectionOffersByExternalRef(
    String externalRef,
  );
}
