import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_platform.dart';

part 'channel_database.g.dart';

/// Drift database for managing chat channels and their associated contact
/// cards.
///
/// This database defines the persistence layer for channel metadata,
/// including channel records ([Channels]) and related contact card
/// information ([ChannelContactCards]).
///
/// It enables secure, encrypted storage using the provided passphrase
/// and ensures referential integrity by enforcing SQLite foreign keys.
@DriftDatabase(tables: [Channels, ChannelContactCards])
class ChannelDatabase extends _$ChannelDatabase {
  /// Constructs a [ChannelDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [directory]: The directory where the database file is stored.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - An instance of [ChannelDatabase].
  ChannelDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
    bool inMemory = false,
  }) : super(
          openConnection(
            databaseName: databaseName,
            passphrase: passphrase,
            directory: directory,
            logStatements: logStatements,
            inMemory: inMemory,
          ),
        );

  /// Opens a [ChannelDatabase] from an existing [connection].
  ///
  /// Intended for migration and schema verification tests only — avoids the
  /// encryption setup performed by the primary constructor.
  @visibleForTesting
  ChannelDatabase.forTesting(DatabaseConnection super.connection);

  /// The current schema version of the database.
  @override
  int get schemaVersion => 4;

  /// Migration strategy to handle database version upgrades.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
              channels,
              channels.isConnectionInitiator,
            );
            // The v1 channel_contact_cards table stored contact fields as
            // individual columns (first_name, last_name, email, mobile,
            // profile_pic, meetingplace_identity_card_color).  Recreate the
            // table with the v2 shape (contact_info_json JSON blob) and
            // migrate the existing data by folding the old columns into a
            // JSON object.  Using a temp-table approach keeps the migration
            // idempotent: a prior interrupted run leaves no partial state.
            await customStatement(
                'DROP TABLE IF EXISTS channel_contact_cards_temp');
            await customStatement('''
              CREATE TABLE channel_contact_cards_temp (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                channel_id TEXT REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
                did TEXT NOT NULL,
                type TEXT NOT NULL,
                contact_info_json TEXT NOT NULL DEFAULT '{}',
                card_type INTEGER NOT NULL,
                UNIQUE(channel_id, card_type)
              )
            ''');
            await customStatement('''
              INSERT INTO channel_contact_cards_temp
                (id, channel_id, did, type, contact_info_json, card_type)
              SELECT
                id, channel_id, did, type,
                json_object(
                  'n', json_object(
                    'given', first_name,
                    'surname', last_name
                  ),
                  'email', email,
                  'mobile', mobile,
                  'photo', profile_pic,
                  'color', meetingplace_identity_card_color
                ),
                card_type
              FROM channel_contact_cards
            ''');
            await customStatement('DROP TABLE channel_contact_cards');
            await customStatement(
              'ALTER TABLE channel_contact_cards_temp RENAME TO channel_contact_cards',
            );
          }
          if (from < 3 && to >= 3) {
            await migrator.addColumn(
              channelContactCards,
              channelContactCards.profilePic,
            );
          }
          if (from < 4 && to >= 4) {
            await migrator.addColumn(
              channels,
              channels.matrixRoomId,
            );
          }
        },
      );
}

/// Table representing chat channels.
@DataClassName('Channel')
@TableIndex(name: 'offer_link', columns: {#offerLink})
class Channels extends Table {
  /// Unique identifier for the channel.
  TextColumn get id => text().clientDefault(const Uuid().v4)();

  /// DID of the channel creator used when publishing the offer.
  TextColumn get publishOfferDid => text()();

  /// DID of the mediator.
  TextColumn get mediatorDid => text()();

  /// Link to the offer.
  TextColumn get offerLink => text()();

  /// Status of the channel.
  IntColumn get status => integer().map(const _ChannelStatusConverter())();

  /// Type of the channel.
  IntColumn get type => integer().map(const _ChannelTypeConverter())();

  /// Indicates whether the channel was initiated by the local party or the
  /// other party.
  BoolColumn get isConnectionInitiator =>
      boolean().withDefault(const Constant(false))();

  /// ID of the outbound message.
  TextColumn get outboundMessageId => text().nullable()();

  /// DID of the accepted offer.
  TextColumn get acceptOfferDid => text().nullable()();

  /// Permanent DID of the channel.
  TextColumn get permanentChannelDid => text().nullable()();

  /// Permanent DID of the other party in the channel.
  TextColumn get otherPartyPermanentChannelDid => text().nullable()();

  /// Notification token for the channel.
  TextColumn get notificationToken => text().nullable()();

  /// Notification token for the other party in the channel.
  TextColumn get otherPartyNotificationToken => text().nullable()();

  /// Matrix room ID associated with the channel.
  TextColumn get matrixRoomId => text().nullable()();

  /// External reference for the channel.
  TextColumn get externalRef => text().nullable()();

  /// Sequence number for the channel that is used to order messages within the
  /// channel.
  IntColumn get seqNo => integer()();

  /// Message sync marker for the channel.
  DateTimeColumn get messageSyncMarker => dateTime().nullable()();

  /// Primary key for the channels table.
  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing contact cards associated with channels.
@DataClassName('ChannelContactCard')
class ChannelContactCards extends Table {
  /// Auto-incrementing ID for the contact card.
  IntColumn get id => integer().autoIncrement()();

  /// ID of the associated channel.
  TextColumn get channelId => text().customConstraint(
        'REFERENCES channels(id) ON DELETE CASCADE NOT NULL',
      )();

  /// DID of the contact.
  TextColumn get did => text()();

  /// Type of the contact.
  TextColumn get type => text()();

  /// Flexible JSON payload for contact information.
  TextColumn get contactInfoJson => text().withDefault(const Constant('{}'))();

  /// Profile picture of the contact.
  TextColumn get profilePic => text().nullable()();

  /// Type of the contact card.
  IntColumn get cardType => integer().map(const _ContactCardTypeConverter())();

  /// Unique keys for the contact cards table.
  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId, cardType},
      ];
}

/// Enumeration representing the type of ContactCard.
enum ContactCardType {
  mine(1),
  other(2);

  const ContactCardType(this.value);
  final int value;
}

class _ContactCardTypeConverter extends TypeConverter<ContactCardType, int> {
  const _ContactCardTypeConverter();

  @override
  ContactCardType fromSql(int fromDb) {
    return ContactCardType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ContactCardType value) {
    return value.value;
  }
}

extension _ChannelStatusValue on ChannelStatus {
  int get value {
    switch (this) {
      case ChannelStatus.approved:
        return 1;
      case ChannelStatus.inaugurated:
        return 2;
      case ChannelStatus.waitingForApproval:
        return 3;
    }
  }
}

class _ChannelStatusConverter extends TypeConverter<ChannelStatus, int> {
  const _ChannelStatusConverter();

  @override
  ChannelStatus fromSql(int fromDb) {
    return ChannelStatus.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ChannelStatus value) {
    return value.value;
  }
}

extension _ChannelTypeValue on ChannelType {
  int get value {
    switch (this) {
      case ChannelType.individual:
        return 1;
      case ChannelType.group:
        return 2;
      case ChannelType.oob:
        return 3;
    }
  }
}

class _ChannelTypeConverter extends TypeConverter<ChannelType, int> {
  const _ChannelTypeConverter();

  @override
  ChannelType fromSql(int fromDb) {
    return ChannelType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ChannelType value) {
    return value.value;
  }
}
