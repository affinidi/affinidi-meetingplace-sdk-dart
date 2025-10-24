import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../storage/storage.dart';

class ConnectionOfferNotFoundException implements Exception {
  ConnectionOfferNotFoundException(this.offerLink);

  final String offerLink;

  @override
  String toString() =>
      '''ConnectionOfferNotFoundException: connection offer not found for $offerLink''';
}

class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl({required Storage storage}) : _storage = storage;

  static const String channelPrefix = 'channel_';
  static const String channelOtherPartyPermanentChannelDidPrefix =
      'channel_other_party_';
  static const String channelOfferLinkPrefix = 'channel_offerlink_';

  final Storage _storage;

  @override
  Future<void> createChannel(Channel channel) async {
    return _writeChannel(channel);
  }

  @override
  Future<Channel?> findChannelByDid(String did) async {
    final channel = await _storage.get<String>('$channelPrefix$did');
    final otherChannel = await _storage.get<String>(
      '$channelOtherPartyPermanentChannelDidPrefix$did',
    );
    if (channel == null && otherChannel == null) return null;

    return Channel.fromJson(
      json.decode(channel ?? otherChannel!) as Map<String, dynamic>,
    );
  }

  @override
  Future<Channel?> findChannelByOtherPartyPermanentChannelDid(
    String did,
  ) async {
    final channel = await _storage.get<String>(
      '$channelOtherPartyPermanentChannelDidPrefix$did',
    );
    if (channel == null) return null;
    return Channel.fromJson(json.decode(channel) as Map<String, dynamic>);
  }

  @override
  Future<Channel?> findChannelByOfferLink(String offerLink) async {
    final permanentChanneDid = await _storage.get<String>(
      '$channelOfferLinkPrefix$offerLink',
    );
    if (permanentChanneDid == null) return null;

    final channel = await _storage.get<String>(
      '$channelPrefix$permanentChanneDid',
    );
    return Channel.fromJson(json.decode(channel!) as Map<String, dynamic>);
  }

  @override
  Future<void> updateChannel(Channel channel) async {
    return _writeChannel(channel);
  }

  @override
  Future<void> deleteChannel(Channel channel) async {
    await _storage.remove('$channelPrefix${channel.id}');
    await _storage.remove('$channelPrefix${channel.permanentChannelDid}');
    if (channel.otherPartyPermanentChannelDid != null) {
      await _storage.remove(
        '''$channelOtherPartyPermanentChannelDidPrefix${channel.otherPartyPermanentChannelDid}''',
      );
    }

    await _storage.remove('$channelOfferLinkPrefix${channel.offerLink}');
  }

  Future<void> _writeChannel(Channel channel) async {
    await _storage.put(
      '$channelPrefix${channel.id}',
      json.encode(channel.toJson()),
    );

    await _storage.put(
      '$channelPrefix${channel.permanentChannelDid}',
      json.encode(channel.toJson()),
    );

    if (channel.otherPartyPermanentChannelDid != null) {
      await _storage.put(
        '''$channelOtherPartyPermanentChannelDidPrefix${channel.otherPartyPermanentChannelDid}''',
        json.encode(channel.toJson()),
      );
    }

    await _storage.put(
      '$channelOfferLinkPrefix${channel.offerLink}',
      channel.permanentChannelDid,
    );
  }
}
