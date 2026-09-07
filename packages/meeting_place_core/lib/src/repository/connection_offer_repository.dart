import '../entity/connection_offer.dart';
import '../entity/group_connection_offer.dart';

/// Persists and retrieves [ConnectionOffer] entities, including
/// [GroupConnectionOffer]s.
///
/// Implementations back the SDK's offer state with durable storage (for
/// example a Drift/SQLite database) so offers survive across app restarts.
abstract interface class ConnectionOfferRepository {
  /// Finds a connection offer by its [offerLink].
  ///
  /// Returns `null` if no matching offer exists.
  Future<ConnectionOffer?> findConnectionOfferByOfferLink(String offerLink);

  /// Finds a connection offer by its [permanentChannelDid].
  ///
  /// Returns `null` if no matching offer exists.
  Future<ConnectionOffer?> findConnectionOfferByPermanentChannelDid(
    String permanentChannelDid,
  );

  /// Finds a [GroupConnectionOffer] by its [groupDid].
  ///
  /// Returns `null` if no matching offer exists.
  Future<ConnectionOffer?> findConnectionOfferByGroupDid(String groupDid);

  /// Returns every stored connection offer.
  Future<List<ConnectionOffer>> listConnectionOffers();

  /// Persists a new [connectionOffer], including its contact card and, for
  /// [GroupConnectionOffer]s, group data.
  Future<void> createConnectionOffer(ConnectionOffer connectionOffer);

  /// Replaces the stored offer matching [connectionOffer]'s offer link with
  /// [connectionOffer].
  ///
  /// Implementations are expected to throw if no offer with that offer link
  /// exists yet.
  Future<void> updateConnectionOffer(ConnectionOffer connectionOffer);

  /// Deletes the stored offer matching [connectionOffer]'s offer link, if
  /// any.
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer);

  /// Returns every connection offer whose [externalRef] matches
  /// [externalRef].
  Future<List<ConnectionOffer>> getConnectionOffersByExternalRef(
    String externalRef,
  );
}
