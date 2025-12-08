import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;

import '../../exceptions/meeting_place_core_repository_error_code.dart';
import '../../exceptions/meeting_place_core_repository_exception.dart';
import '../../extensions/contact_card_extensions.dart';
import 'channel_database.dart' as db;

/// Repository implementation for managing [model.Channel] entities
/// using a Drift-backed [db.ChannelDatabase].
///
/// This repository encapsulates persistence and retrieval logic
/// for channels and their associated contact cards.
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

  /// Inserts a new [model.Channel] into the database,
  /// along with its contact cards.
  ///
  /// - [channel]: The channel domain model containing metadata and
  ///   optional self ([model.ContactCard]) and other party
  ///   ([model.ContactCard]) contact details.
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

      final card = channel.card;
      if (card != null) {
        await _insertContactCardType(
          channelId: channelId,
          card: card,
          type: db.ContactCardType.mine,
        );
      }
      final otherCard = channel.otherPartyCard;
      if (otherCard != null) {
        await _insertContactCardType(
          channelId: channelId,
          card: otherCard,
          type: db.ContactCardType.other,
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

  /// Updates a [model.Channel] and its associated contact cards.
  ///
  /// - [channel]: The updated channel domain model.
  ///
  /// Throws [MeetingPlaceCoreRepositoryException] if the channel does not
  /// exist. Updates run inside a transaction to maintain consistency.
  @override
  Future<void> updateChannel(model.Channel channel) async {
    await _database.transaction(() async {
      final query = _database.select(_database.channels)
        ..where((c) => _database.channels.id.equals(channel.id));
      final results = await query.getSingleOrNull();
      if (results == null) {
        throw MeetingPlaceCoreRepositoryException(
          'Trying to update a channel that does not exists',
          code: MeetingPlaceCoreRepositoryErrorCode.missingChannel,
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

      final card = channel.card;
      await _upsertContactCardType(
        channelId: channelId,
        card: card,
        type: db.ContactCardType.mine,
      );

      final otherCard = channel.otherPartyCard;
      await _upsertContactCardType(
        channelId: channelId,
        card: otherCard,
        type: db.ContactCardType.other,
      );
    });
  }

  Future<void> _upsertContactCardType({
    required String channelId,
    required model.ContactCard? card,
    required db.ContactCardType type,
  }) async {
    final cardExistQuery = _database.select(_database.channelContactCards)
      ..where(
        (c) =>
            _database.channelContactCards.channelId.equals(channelId) &
            _database.channelContactCards.cardType.equals(type.value),
      );
    final existingCard = await cardExistQuery.getSingleOrNull();

    if (existingCard != null) {
      await _updateContactCardType(
          channelId: channelId, card: card, type: type);
      return;
    }

    if (card == null) return;
    await _insertContactCardType(channelId: channelId, card: card, type: type);
  }

  /// Internal helper to insert a contact card of a specific type for a channel.
  /// Used during channel creation.
  Future<void> _insertContactCardType({
    required String channelId,
    required model.ContactCard card,
    required db.ContactCardType type,
  }) async {
    await _database.into(_database.channelContactCards).insert(
          db.ChannelContactCardsCompanion(
            channelId: Value(channelId),
            firstName: Value(card.firstName),
            lastName: Value(card.lastName),
            email: Value(card.email),
            mobile: Value(card.mobile),
            profilePic: Value(card.profilePic),
            meetingplaceIdentityCardColor: Value(
              card.meetingplaceIdentityCardColor,
            ),
            cardType: Value(type),
          ),
        );
  }

  /// Internal helper to update or delete a contact card for a channel.
  /// If `card` is not null, updates the existing record; otherwise removes it.
  Future<void> _updateContactCardType({
    required String channelId,
    required model.ContactCard? card,
    required db.ContactCardType type,
  }) async {
    if (card != null) {
      await (_database.update(_database.channelContactCards)
            ..where(
              (c) =>
                  _database.channelContactCards.channelId.equals(channelId) &
                  _database.channelContactCards.cardType.equals(type.value),
            ))
          .write(
        db.ChannelContactCardsCompanion(
          firstName: Value(card.firstName),
          lastName: Value(card.lastName),
          email: Value(card.email),
          mobile: Value(card.mobile),
          profilePic: Value(card.profilePic),
          meetingplaceIdentityCardColor: Value(
            card.meetingplaceIdentityCardColor,
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
  /// Joins the [db.Channels] table with both `mine` and `other` contact-card
  /// tables
  /// to return a fully hydrated [model.Channel].
  Future<model.Channel?> _getChannelByPredicate(
    Expression<bool> predicate,
  ) async {
    final myCard = _database.alias(_database.channelContactCards, 'card');
    final otherCard = _database.alias(
      _database.channelContactCards,
      'otherCard',
    );

    final query = _database.select(_database.channels).join([
      leftOuterJoin(
        myCard,
        myCard.channelId.equalsExp(_database.channels.id) &
            myCard.cardType.equals(db.ContactCardType.mine.value),
      ),
      leftOuterJoin(
        otherCard,
        otherCard.channelId.equalsExp(_database.channels.id) &
            otherCard.cardType.equals(db.ContactCardType.other.value),
      ),
    ])
      ..where(predicate);

    final results = await query.getSingleOrNull();
    if (results == null) return null;

    return _ChannelMapper.fromDatabaseRecords(
      results.readTable(_database.channels),
      results.readTableOrNull(myCard),
      results.readTableOrNull(otherCard),
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
      card: _makeContactCardFromDb(contactCard),
      otherPartyCard: _makeContactCardFromDb(otherContactCard),
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

  static model.ContactCard? _makeContactCardFromDb(
    db.ChannelContactCard? contactCard,
  ) {
    if (contactCard == null) return null;
    final contactInfo = <String, dynamic>{
      'n': {
        'given': contactCard.firstName,
        'surname': contactCard.lastName,
      },
      'email': {
        'type': {'work': contactCard.email}
      },
      'tel': {
        'type': {'cell': contactCard.mobile}
      },
      'photo': contactCard.profilePic,
      'x-meetingplace-identity-card-color':
          contactCard.meetingplaceIdentityCardColor,
    };
    return model.ContactCard(
      did: '',
      type: 'contactCard',
      contactInfo: contactInfo,
    );
  }
}
