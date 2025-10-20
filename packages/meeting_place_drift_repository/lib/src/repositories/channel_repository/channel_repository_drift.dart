import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;

import '../../exceptions/mpx_repository_exception.dart';
import '../../exceptions/mpx_repository_exception_type.dart';
import '../../extensions/vcard_extensions.dart';
import 'channel_database.dart' as db;

/// Repository implementation for managing [model.Channel] entities
/// using a Drift-backed [db.ChannelDatabase].
///
/// This repository encapsulates persistence and retrieval logic
/// for channels and their associated contact cards (vCards).
/// It supports creation, update, lookup, and deletion operations
/// while ensuring data consistency with transactions.
class ChannelRepositoryDrift implements model.ChannelRepository {
  /// Creates a new repository with the given [database].
  ///
  /// - [database]: The Drift [db.ChannelDatabase] instance used for
  ///   executing all channel-related persistence operations.
  ChannelRepositoryDrift({required db.ChannelDatabase database})
      : _database = database;

  final db.ChannelDatabase _database;

  /// Inserts a new [model.Channel] into the database, along with its vCards.
  ///
  /// - [channel]: The channel domain model containing metadata and
  ///   optional self ([model.VCard]) and other party
  ///  (otherPartyVCard) contact details.
  ///
  /// Runs inside a database transaction to ensure atomicity.
  @override
  Future<void> createChannel(model.Channel channel) async {
    await _database.transaction(() async {
      final channelId = channel.id;
      await _database.into(_database.channels).insert(
            db.ChannelsCompanion(
              id: Value(channelId),
              offerLink: Value(channel.offerLink),
              publishOfferDid: Value(channel.publishOfferDid),
              status: Value(channel.status),
              type: Value(channel.type),
              outboundMessageId: Value(channel.outboundMessageId),
              acceptOfferDid: Value(channel.acceptOfferDid),
              permanentChannelDid: Value(channel.permanentChannelDid),
              otherPartyPermanentChannelDid: Value(
                channel.otherPartyPermanentChannelDid,
              ),
              notificationToken: Value(channel.notificationToken),
              otherPartyNotificationToken: Value(
                channel.otherPartyNotificationToken,
              ),
              seqNo: Value(channel.seqNo),
              messageSyncMarker: Value(channel.messageSyncMarker),
              mediatorDid: Value(channel.mediatorDid),
              externalRef: Value(channel.externalRef),
            ),
          );

      final vCard = channel.vCard;
      if (vCard != null) {
        await _insertVCardType(
          channelId: channelId,
          vCard: vCard,
          type: db.VCardType.mine,
        );
      }
      final otherPartyVCard = channel.otherPartyVCard;
      if (otherPartyVCard != null) {
        await _insertVCardType(
          channelId: channelId,
          vCard: otherPartyVCard,
          type: db.VCardType.other,
        );
      }
    });
  }

  /// Retrieves a channel by its permanent channel DID or other party DID.
  ///
  /// - [did]: The DID string to search for.
  ///
  /// Returns a [model.Channel] if found, or `null` otherwise.
  @override
  Future<model.Channel?> findChannelByDid(String did) => _getChannelByPredicate(
        _database.channels.permanentChannelDid.equals(did) |
            _database.channels.otherPartyPermanentChannelDid.equals(did),
      );

  /// Retrieves a channel by the other party’s permanent channel DID.
  ///
  /// - [did]: The other party's permanent DID.
  ///
  /// Returns a [model.Channel] if found, or `null` otherwise.
  @override
  Future<model.Channel?> findChannelByOtherPartyPermanentChannelDid(
    String did,
  ) =>
      _getChannelByPredicate(
        _database.channels.otherPartyPermanentChannelDid.equals(did),
      );

  /// Retrieves a channel by its [offerLink].
  ///
  /// - [offerLink]: The link originally used to create or join the channel.
  ///
  /// Returns a [model.Channel] if found, or `null` otherwise.
  @override
  Future<model.Channel?> findChannelByOfferLink(String offerLink) =>
      _getChannelByPredicate(_database.channels.offerLink.equals(offerLink));

  /// Updates a [model.Channel] and its associated vCards.
  ///
  /// - [channel]: The updated channel domain model.
  ///
  /// Throws [MpxRepositoryException] if the channel does not exist.
  /// Updates run inside a transaction to maintain consistency.
  @override
  Future<void> updateChannel(model.Channel channel) async {
    await _database.transaction(() async {
      final query = _database.select(_database.channels)
        ..where((c) => _database.channels.id.equals(channel.id));
      final results = await query.getSingleOrNull();
      if (results == null) {
        throw MpxRepositoryException(
          'Trying to update a channel that does not exists',
          type: MpxRepositoryExceptionType.missingChannel.name,
        );
      }

      final channelId = results.id;
      await (_database.update(
        _database.channels,
      )..where((c) => c.id.equals(channelId)))
          .write(
        db.ChannelsCompanion(
          offerLink: Value(channel.offerLink),
          publishOfferDid: Value(channel.publishOfferDid),
          status: Value(channel.status),
          type: Value(channel.type),
          outboundMessageId: Value(channel.outboundMessageId),
          acceptOfferDid: Value(channel.acceptOfferDid),
          permanentChannelDid: Value(channel.permanentChannelDid),
          otherPartyPermanentChannelDid: Value(
            channel.otherPartyPermanentChannelDid,
          ),
          notificationToken: Value(channel.notificationToken),
          otherPartyNotificationToken: Value(
            channel.otherPartyNotificationToken,
          ),
          seqNo: Value(channel.seqNo),
          messageSyncMarker: Value(channel.messageSyncMarker),
          mediatorDid: Value(channel.mediatorDid),
          externalRef: Value(channel.externalRef),
        ),
      );

      final vCard = channel.vCard;
      await _upsertVCardType(
        channelId: channelId,
        vCard: vCard,
        type: db.VCardType.mine,
      );

      final otherPartyVCard = channel.otherPartyVCard;
      await _upsertVCardType(
        channelId: channelId,
        vCard: otherPartyVCard,
        type: db.VCardType.other,
      );
    });
  }

  Future<void> _upsertVCardType({
    required String channelId,
    required model.VCard? vCard,
    required db.VCardType type,
  }) async {
    final vCardExistQuery = _database.select(_database.channelContactCards)
      ..where(
        (c) =>
            _database.channelContactCards.channelId.equals(channelId) &
            _database.channelContactCards.cardType.equals(type.value),
      );
    final existingVCard = await vCardExistQuery.getSingleOrNull();

    if (existingVCard != null) {
      await _updateVCardType(channelId: channelId, vCard: vCard, type: type);
      return;
    }

    if (vCard == null) return;
    await _insertVCardType(channelId: channelId, vCard: vCard, type: type);
  }

  /// Internal helper to insert a vCard of a specific [type] for a [channelId].
  ///
  /// Used during channel creation.
  Future<void> _insertVCardType({
    required String channelId,
    required model.VCard vCard,
    required db.VCardType type,
  }) async {
    await _database.into(_database.channelContactCards).insert(
          db.ChannelContactCardsCompanion(
            channelId: Value(channelId),
            firstName: Value(vCard.firstName),
            lastName: Value(vCard.lastName),
            email: Value(vCard.email),
            mobile: Value(vCard.mobile),
            profilePic: Value(vCard.profilePic),
            meetingplaceIdentityCardColor: Value(
              vCard.meetingplaceIdentityCardColor,
            ),
            cardType: Value(type),
          ),
        );
  }

  /// Internal helper to update or delete a vCard of a specific [type]
  ///  for a [channelId].
  ///
  /// - If [vCard] is not `null`, updates the existing record.
  /// - If [vCard] is `null`, removes the vCard entry.
  Future<void> _updateVCardType({
    required String channelId,
    required model.VCard? vCard,
    required db.VCardType type,
  }) async {
    if (vCard != null) {
      await (_database.update(_database.channelContactCards)
            ..where(
              (c) =>
                  _database.channelContactCards.channelId.equals(channelId) &
                  _database.channelContactCards.cardType.equals(type.value),
            ))
          .write(
        db.ChannelContactCardsCompanion(
          firstName: Value(vCard.firstName),
          lastName: Value(vCard.lastName),
          email: Value(vCard.email),
          mobile: Value(vCard.mobile),
          profilePic: Value(vCard.profilePic),
          meetingplaceIdentityCardColor: Value(
            vCard.meetingplaceIdentityCardColor,
          ),
          cardType: Value(type),
        ),
      );
    } else {
      await (_database.delete(_database.channelContactCards)
            ..where(
              (filter) =>
                  filter.channelId.equals(channelId) &
                  filter.cardType.equals(type.value),
            ))
          .go();
    }
  }

  /// Internal helper to retrieve a channel using an arbitrary [predicate].
  ///
  /// Joins the [db.Channels] table with both `mine` and `other` vCard tables
  /// to return a fully hydrated [model.Channel].
  Future<model.Channel?> _getChannelByPredicate(
    Expression<bool> predicate,
  ) async {
    final vCard = _database.alias(_database.channelContactCards, 'vcard');
    final otherVCard = _database.alias(
      _database.channelContactCards,
      'otherVCard',
    );

    final query = _database.select(_database.channels).join([
      leftOuterJoin(
        vCard,
        vCard.channelId.equalsExp(_database.channels.id) &
            vCard.cardType.equals(db.VCardType.mine.value),
      ),
      leftOuterJoin(
        otherVCard,
        otherVCard.channelId.equalsExp(_database.channels.id) &
            otherVCard.cardType.equals(db.VCardType.other.value),
      ),
    ])
      ..where(predicate);

    final results = await query.getSingleOrNull();
    if (results == null) return null;

    return _ChannelMapper.fromDatabaseRecords(
      results.readTable(_database.channels),
      results.readTableOrNull(vCard),
      results.readTableOrNull(otherVCard),
    );
  }

  /// Deletes a [model.Channel] from the database.
  ///
  /// - [channel]: The channel to delete (only its id is required).
  @override
  Future<void> deleteChannel(model.Channel channel) async {
    await (_database.delete(
      _database.channels,
    )..where((filter) => filter.id.equals(channel.id)))
        .go();
  }
}

class _ChannelMapper {
  static model.Channel fromDatabaseRecords(
    db.Channel channel,
    db.ChannelContactCard? contactCard,
    db.ChannelContactCard? otherContactCard,
  ) {
    return model.Channel(
      id: channel.id,
      offerLink: channel.offerLink,
      publishOfferDid: channel.publishOfferDid,
      mediatorDid: channel.mediatorDid,
      status: channel.status,
      type: channel.type,
      vCard: _makeVCardFromContactCard(contactCard),
      otherPartyVCard: _makeVCardFromContactCard(otherContactCard),
      acceptOfferDid: channel.acceptOfferDid,
      permanentChannelDid: channel.permanentChannelDid,
      otherPartyPermanentChannelDid: channel.otherPartyPermanentChannelDid,
      notificationToken: channel.notificationToken,
      otherPartyNotificationToken: channel.otherPartyNotificationToken,
      seqNo: channel.seqNo,
      messageSyncMarker: channel.messageSyncMarker?.toUtc(),
      externalRef: channel.externalRef,
    );
  }

  static model.VCard? _makeVCardFromContactCard(
    db.ChannelContactCard? contactCard,
  ) {
    if (contactCard == null) return null;

    final vCard = model.VCard(values: {});
    vCard.firstName = contactCard.firstName;
    vCard.lastName = contactCard.lastName;
    vCard.email = contactCard.email;
    vCard.mobile = contactCard.mobile;
    vCard.profilePic = contactCard.profilePic;
    vCard.meetingplaceIdentityCardColor =
        contactCard.meetingplaceIdentityCardColor;

    return vCard;
  }
}
