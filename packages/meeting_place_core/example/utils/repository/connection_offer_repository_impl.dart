import 'dart:convert';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../storage.dart';

class ConnectionOfferNotFoundException implements Exception {
  ConnectionOfferNotFoundException(this.offerLink);

  final String offerLink;

  @override
  String toString() =>
      '''ConnectionOfferNotFoundException: connection offer not found for $offerLink''';
}

class ConnectionOfferRepositoryImpl implements ConnectionOfferRepository {
  ConnectionOfferRepositoryImpl({required InMemoryStorage storage})
      : _storage = storage;

  static const String connectionPrefix = 'connection_';
  static const String channelPrefix = 'channel_';
  static const String channelOfferLinkPrefix = 'channel_offerlink_';
  static const String permanentChannelDidPrefix = 'permanent_channel_did_';
  static const String connectionGroupRelationPrefix = 'connection_group_rel_';

  final InMemoryStorage _storage;
  @override
  Future<void> createConnectionOffer(ConnectionOffer connection) async {
    await _storage.put(
      '$connectionPrefix${connection.offerLink}',
      json.encode(connection.toJson()),
    );

    if (connection.permanentChannelDid != null) {
      await _storage.put(
        '$permanentChannelDidPrefix${connection.permanentChannelDid}',
        connection.offerLink,
      );
    }
  }

  @override
  Future<void> updateConnectionOffer(ConnectionOffer connection) async {
    await _storage.put(
      '$connectionPrefix${connection.offerLink}',
      json.encode(connection.toJson()),
    );

    if (connection.permanentChannelDid != null) {
      await _storage.put(
        '$permanentChannelDidPrefix${connection.permanentChannelDid}',
        connection.offerLink,
      );
    }
  }

  @override
  Future<ConnectionOffer?> getConnectionOfferByOfferLink(
    String offerLink,
  ) async {
    final connection =
        await _storage.get<String>('$connectionPrefix$offerLink');

    if (connection == null) return null;
    return _connectionOfferFromEncodedJson(connection);
  }

  ConnectionOffer _connectionOfferFromEncodedJson(String connectionJson) {
    final decoded = json.decode(connectionJson) as Map<String, dynamic>;
    return _connectionOfferFromDecodedJson(decoded);
  }

  ConnectionOffer _connectionOfferFromDecodedJson(Map<String, dynamic> json) {
    if (json.containsKey('groupId')) {
      return GroupConnectionOffer.fromJson(json);
    }

    return ConnectionOffer.fromJson(json);
  }

  @override
  Future<List<ConnectionOffer>> listConnectionOffers() async {
    final connectionOffers = await _storage
        .getCollection<MapEntry<String, dynamic>>(connectionPrefix);

    final list = <ConnectionOffer>[];
    for (final connectionOffer in connectionOffers) {
      list.add(
        _connectionOfferFromEncodedJson(connectionOffer.value as String),
      );
    }

    return list;
  }

  @override
  Future<ConnectionOffer?> getConnectionOfferByPermanentChannelDid(
    String permanentChannelDid,
  ) async {
    final offerLink = await _storage.get<String>(
      '$permanentChannelDidPrefix$permanentChannelDid',
    );
    if (offerLink == null) return null;

    return getConnectionOfferByOfferLink(offerLink);
  }

  @override
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer) async {
    final offerLink = connectionOffer.offerLink;
    await _storage.remove('$connectionPrefix$offerLink');
  }

  @override
  Future<ConnectionOffer?> getConnectionOfferByGroupDid(String groupDid) async {
    final offerLink = await _storage.get<String>(
      '$connectionGroupRelationPrefix$groupDid',
    );

    if (offerLink == null) return null;
    return getConnectionOfferByOfferLink(offerLink);
  }
}
