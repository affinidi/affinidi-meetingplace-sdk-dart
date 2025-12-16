import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;
import 'package:uuid/uuid.dart';

import '../../exceptions/meeting_place_core_repository_error_code.dart';
import '../../exceptions/meeting_place_core_repository_exception.dart';
import '../../extensions/contact_card_extensions.dart';
import 'connection_offer_database.dart' as db;

/// [ConnectionOfferRepositoryDrift] provides a Drift-based
/// implementation of the [model.ConnectionOfferRepository].
///
/// It manages persistence and retrieval of connection offers,
/// including group offers and associated contact cards.
///
/// ### Responsibilities:
/// - Store new [model.ConnectionOffer] and [model.GroupConnectionOffer]
/// records.
/// - Update existing offers and synchronize related tables
///   (`groupConnectionOffers`, `connectionContactCards`).
/// - Delete offers and their related entities (via foreign key cascade).
/// - Query offers by:
///   - offerLink
///   - permanentChannelDid
///   - groupDid
/// - Return fully hydrated domain models (including [model.ContactCard]).
///
/// ### Parameters:
/// - database: The Drift [db.ConnectionOfferDatabase] instance to use.
class ConnectionOfferRepositoryDrift
    implements model.ConnectionOfferRepository {
  /// Constructs a [ConnectionOfferRepositoryDrift] with the provided
  /// [db.ConnectionOfferDatabase] instance.
  ///
  /// **Parameters:**
  /// - [database]: The Drift database instance for connection offers.
  ///
  /// **Returns:**
  /// - An instance of [ConnectionOfferRepositoryDrift].
  ConnectionOfferRepositoryDrift({required db.ConnectionOfferDatabase database})
      : _database = database;

  final db.ConnectionOfferDatabase _database;

  /// Private helper to retrieve a [model.ConnectionOffer] using
  /// an arbitrary [predicate].
  ///
  /// Joins:
  /// - connectionOffers
  /// - groupConnectionOffers (optional)
  /// - connectionContactCards
  ///
  /// Returns:
  /// - A fully constructed [model.ConnectionOffer]
  ///   (or [model.GroupConnectionOffer])
  ///   with its [model.ContactCard].
  Future<model.ConnectionOffer?> _getConnectionOfferByPredicate(
    Expression<bool> predicate,
  ) async {
    final query = _database.select(_database.connectionOffers).join([
      leftOuterJoin(
        _database.groupConnectionOffers,
        _database.groupConnectionOffers.connectionOfferId.equalsExp(
          _database.connectionOffers.id,
        ),
      ),
      leftOuterJoin(
        _database.connectionContactCards,
        _database.connectionContactCards.connectionOfferId.equalsExp(
          _database.connectionOffers.id,
        ),
      ),
    ])
      ..where(predicate);

    final results = await query.getSingleOrNull();
    if (results == null) return null;

    return _ConnectionOfferMapper.fromDatabaseRecords(
      results.readTable(_database.connectionOffers),
      results.readTableOrNull(_database.groupConnectionOffers),
      results.readTable(_database.connectionContactCards),
    );
  }

  /// Finds a [model.ConnectionOffer] by its [offerLink].
  @override
  Future<model.ConnectionOffer?> getConnectionOfferByOfferLink(
    String offerLink,
  ) =>
      _getConnectionOfferByPredicate(
        _database.connectionOffers.offerLink.equals(offerLink),
      );

  /// Finds a [model.ConnectionOffer] by its [permanentChannelDid].
  @override
  Future<model.ConnectionOffer?> getConnectionOfferByPermanentChannelDid(
    String permanentChannelDid,
  ) =>
      _getConnectionOfferByPredicate(
        _database.connectionOffers.permanentChannelDid
            .equals(permanentChannelDid),
      );

  /// Finds a [model.ConnectionOffer] by its [groupDid].
  ///
  /// Only applicable for [model.GroupConnectionOffer]s.
  @override
  Future<model.ConnectionOffer?> getConnectionOfferByGroupDid(
    String groupDid,
  ) =>
      _getConnectionOfferByPredicate(
        _database.groupConnectionOffers.groupDid.equals(groupDid),
      );

  /// Retrieves all stored [model.ConnectionOffer] records,
  /// including related group offers and contact cards.
  @override
  Future<List<model.ConnectionOffer>> listConnectionOffers() async {
    final results = await _database.select(_database.connectionOffers).join([
      leftOuterJoin(
        _database.groupConnectionOffers,
        _database.groupConnectionOffers.connectionOfferId.equalsExp(
          _database.connectionOffers.id,
        ),
      ),
      leftOuterJoin(
        _database.connectionContactCards,
        _database.connectionContactCards.connectionOfferId.equalsExp(
          _database.connectionOffers.id,
        ),
      ),
    ]).get();

    return results.map((result) {
      return _ConnectionOfferMapper.fromDatabaseRecords(
        result.readTable(_database.connectionOffers),
        result.readTableOrNull(_database.groupConnectionOffers),
        result.readTable(_database.connectionContactCards),
      );
    }).toList();
  }

  /// Persists a new [model.ConnectionOffer] (or [model.GroupConnectionOffer]).
  ///
  /// Inserts into:
  /// - connectionOffers
  /// - groupConnectionOffers (if group)
  /// - connectionContactCards
  ///
  /// Ensures atomicity with a Drift transaction.
  @override
  Future<void> createConnectionOffer(
    model.ConnectionOffer connectionOffer,
  ) async {
    await _database.transaction(() async {
      final connectionOfferId = const Uuid().v4();
      await _database.into(_database.connectionOffers).insert(
            db.ConnectionOffersCompanion(
              id: Value(connectionOfferId),
              offerName: Value(connectionOffer.offerName),
              offerLink: Value(connectionOffer.offerLink),
              offerDescription: Value(connectionOffer.offerDescription),
              oobInvitationMessage: Value(connectionOffer.oobInvitationMessage),
              mnemonic: Value(connectionOffer.mnemonic),
              ownedByMe: Value(connectionOffer.ownedByMe),
              expiresAt: Value(connectionOffer.expiresAt),
              createdAt: Value(connectionOffer.createdAt),
              publishOfferDid: Value(connectionOffer.publishOfferDid),
              type: Value(connectionOffer.type),
              status: Value(connectionOffer.status),
              maximumUsage: Value(connectionOffer.maximumUsage),
              outboundMessageId: Value(connectionOffer.outboundMessageId),
              acceptOfferDid: Value(connectionOffer.acceptOfferDid),
              permanentChannelDid: Value(connectionOffer.permanentChannelDid),
              otherPartyPermanentChannelDid: Value(
                connectionOffer.otherPartyPermanentChannelDid,
              ),
              notificationToken: Value(connectionOffer.notificationToken),
              otherPartyNotificationToken: Value(
                connectionOffer.otherPartyNotificationToken,
              ),
              mediatorDid: Value(connectionOffer.mediatorDid),
              externalRef: Value(connectionOffer.externalRef),
            ),
          );

      if (connectionOffer is model.GroupConnectionOffer) {
        await _database.into(_database.groupConnectionOffers).insert(
              db.GroupConnectionOffersCompanion(
                connectionOfferId: Value(connectionOfferId),
                memberDid: Value(connectionOffer.memberDid!),
                groupId: Value(connectionOffer.groupId),
                groupOwnerDid: Value(connectionOffer.groupOwnerDid),
                groupDid: Value(connectionOffer.groupDid),
                metadata: Value(connectionOffer.metadata),
              ),
            );
      }

      final card = connectionOffer.contactCard;
      await _database.into(_database.connectionContactCards).insert(
            db.ConnectionContactCardsCompanion(
              connectionOfferId: Value(connectionOfferId),
              firstName: Value(card.firstName),
              lastName: Value(card.lastName),
              email: Value(card.email),
              mobile: Value(card.mobile),
              profilePic: Value(card.profilePic),
              meetingplaceIdentityCardColor: Value(
                card.meetingplaceIdentityCardColor,
              ),
            ),
          );
    });
  }

  /// Updates an existing [model.ConnectionOffer].
  ///
  /// - Throws [MeetingPlaceCoreRepositoryException] if the record does not
  ///   exist.
  /// - Updates main offer, group data (if applicable),
  ///   and associated [model.ContactCard] contact card.
  @override
  Future<void> updateConnectionOffer(
    model.ConnectionOffer connectionOffer,
  ) async {
    await _database.transaction(() async {
      final query = _database.select(_database.connectionOffers)
        ..where(
          (c) => _database.connectionOffers.offerLink.equals(
            connectionOffer.offerLink,
          ),
        );
      final results = await query.getSingleOrNull();
      if (results == null) {
        throw MeetingPlaceCoreRepositoryException(
          'Trying to update a connection that does not exists',
          code: MeetingPlaceCoreRepositoryErrorCode.missingConnectionOffer,
        );
      }

      final connectionOfferId = results.id;
      await (_database.update(
        _database.connectionOffers,
      )..where((c) => c.offerLink.equals(connectionOffer.offerLink)))
          .write(
        db.ConnectionOffersCompanion(
          offerName: Value(connectionOffer.offerName),
          offerLink: Value(connectionOffer.offerLink),
          offerDescription: Value(connectionOffer.offerDescription),
          oobInvitationMessage: Value(connectionOffer.oobInvitationMessage),
          mnemonic: Value(connectionOffer.mnemonic),
          ownedByMe: Value(connectionOffer.ownedByMe),
          expiresAt: Value(connectionOffer.expiresAt),
          createdAt: Value(connectionOffer.createdAt),
          publishOfferDid: Value(connectionOffer.publishOfferDid),
          type: Value(connectionOffer.type),
          status: Value(connectionOffer.status),
          maximumUsage: Value(connectionOffer.maximumUsage),
          outboundMessageId: Value(connectionOffer.outboundMessageId),
          acceptOfferDid: Value(connectionOffer.acceptOfferDid),
          permanentChannelDid: Value(connectionOffer.permanentChannelDid),
          otherPartyPermanentChannelDid: Value(
            connectionOffer.otherPartyPermanentChannelDid,
          ),
          notificationToken: Value(connectionOffer.notificationToken),
          otherPartyNotificationToken: Value(
            connectionOffer.otherPartyNotificationToken,
          ),
          mediatorDid: Value(connectionOffer.mediatorDid),
          externalRef: Value(connectionOffer.externalRef),
        ),
      );

      if (connectionOffer is model.GroupConnectionOffer) {
        await (_database.update(_database.groupConnectionOffers)
              ..where(
                (c) => _database.groupConnectionOffers.connectionOfferId.equals(
                  connectionOfferId,
                ),
              ))
            .write(
          db.GroupConnectionOffersCompanion(
            connectionOfferId: Value(connectionOfferId),
            memberDid: Value(connectionOffer.memberDid!),
            groupId: Value(connectionOffer.groupId),
            groupOwnerDid: Value(connectionOffer.groupOwnerDid),
            groupDid: Value(connectionOffer.groupDid),
            metadata: Value(connectionOffer.metadata),
          ),
        );
      } else {
        await (_database.delete(_database.groupConnectionOffers)
              ..where(
                (filter) => filter.connectionOfferId.equals(connectionOfferId),
              ))
            .go();
      }

      final card = connectionOffer.contactCard;
      await (_database.update(_database.connectionContactCards)
            ..where(
              (c) => _database.connectionContactCards.connectionOfferId.equals(
                connectionOfferId,
              ),
            ))
          .write(
        db.ConnectionContactCardsCompanion(
          firstName: Value(card.firstName),
          lastName: Value(card.lastName),
          email: Value(card.email),
          mobile: Value(card.mobile),
          profilePic: Value(card.profilePic),
          meetingplaceIdentityCardColor: Value(
            card.meetingplaceIdentityCardColor,
          ),
        ),
      );
    });
  }

  /// Deletes a [model.ConnectionOffer] by its offerLink.
  ///
  /// Relies on foreign key cascade to also remove group/contact rows.
  @override
  Future<void> deleteConnectionOffer(
    model.ConnectionOffer connectionOffer,
  ) async {
    await (_database.delete(_database.connectionOffers)
          ..where(
            (filter) => filter.offerLink.equals(connectionOffer.offerLink),
          ))
        .go();
  }
}

/// [_ConnectionOfferMapper] transforms raw Drift database records
/// into domain model entities ([model.ConnectionOffer]
/// or [model.GroupConnectionOffer]).
///
/// ### Responsibilities:
/// - Map [model.ConnectionOffer], [model.GroupConnectionOffer]
/// , and [db.ConnectionContactCard]
///   database rows into a complete model.
/// - Construct a [model.ContactCard] from contact card details.
/// - Determine whether to return a base [model.ConnectionOffer]
///   or a [model.GroupConnectionOffer].
class _ConnectionOfferMapper {
  static model.ConnectionOffer fromDatabaseRecords(
    db.ConnectionOffer connectionOffer,
    db.GroupConnectionOffer? groupConnectionOffer,
    db.ConnectionContactCard contactCard,
  ) {
    final card = model.ContactCard(
      did: contactCard.did,
      type: contactCard.type,
      schema: contactCard.schema,
      contactInfo: {
        'firstName': contactCard.firstName,
        'lastName': contactCard.lastName,
        'email': contactCard.email,
        'mobile': contactCard.mobile,
        'profilePic': contactCard.profilePic,
        'meetingplaceIdentityCardColor':
            contactCard.meetingplaceIdentityCardColor
      },
    );

    if (groupConnectionOffer != null) {
      return model.GroupConnectionOffer(
        groupId: groupConnectionOffer.groupId,
        memberDid: groupConnectionOffer.memberDid,
        groupDid: groupConnectionOffer.groupDid,
        groupOwnerDid: groupConnectionOffer.groupOwnerDid,
        metadata: groupConnectionOffer.metadata,
        offerName: connectionOffer.offerName,
        offerLink: connectionOffer.offerLink,
        offerDescription: connectionOffer.offerDescription,
        oobInvitationMessage: connectionOffer.oobInvitationMessage,
        mnemonic: connectionOffer.mnemonic,
        expiresAt: connectionOffer.expiresAt,
        createdAt: connectionOffer.createdAt,
        publishOfferDid: connectionOffer.publishOfferDid,
        mediatorDid: connectionOffer.mediatorDid,
        type: connectionOffer.type,
        status: connectionOffer.status,
        contactCard: card,
        maximumUsage: connectionOffer.maximumUsage,
        ownedByMe: connectionOffer.ownedByMe,
        outboundMessageId: connectionOffer.outboundMessageId,
        acceptOfferDid: connectionOffer.acceptOfferDid,
        permanentChannelDid: connectionOffer.permanentChannelDid,
        otherPartyPermanentChannelDid:
            connectionOffer.otherPartyPermanentChannelDid,
        notificationToken: connectionOffer.notificationToken,
        otherPartyNotificationToken:
            connectionOffer.otherPartyNotificationToken,
        externalRef: connectionOffer.externalRef,
      );
    }

    return model.ConnectionOffer(
      offerName: connectionOffer.offerName,
      offerLink: connectionOffer.offerLink,
      mnemonic: connectionOffer.mnemonic,
      expiresAt: connectionOffer.expiresAt,
      createdAt: connectionOffer.createdAt,
      publishOfferDid: connectionOffer.publishOfferDid,
      mediatorDid: connectionOffer.mediatorDid,
      type: connectionOffer.type,
      status: connectionOffer.status,
      contactCard: card,
      maximumUsage: connectionOffer.maximumUsage,
      ownedByMe: connectionOffer.ownedByMe,
      offerDescription: connectionOffer.offerDescription,
      oobInvitationMessage: connectionOffer.oobInvitationMessage,
      outboundMessageId: connectionOffer.outboundMessageId,
      acceptOfferDid: connectionOffer.acceptOfferDid,
      permanentChannelDid: connectionOffer.permanentChannelDid,
      otherPartyPermanentChannelDid:
          connectionOffer.otherPartyPermanentChannelDid,
      notificationToken: connectionOffer.notificationToken,
      otherPartyNotificationToken: connectionOffer.otherPartyNotificationToken,
      externalRef: connectionOffer.externalRef,
    );
  }
}
