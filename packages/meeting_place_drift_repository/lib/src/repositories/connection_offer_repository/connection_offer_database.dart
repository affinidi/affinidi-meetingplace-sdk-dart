import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_platform.dart';

part 'connection_offer_database.g.dart';

/// [ConnectionOfferDatabase] defines the Drift (SQLite) database
/// for storing connection offers.
///
/// This database instance is encrypted with a passphrase and
/// stored in a specified [Directory].
///
/// Foreign key enforcement is enabled via:
/// ```sql
/// PRAGMA foreign_keys = ON;
/// ```
///
/// ### Parameters:
/// - databaseName: Logical name of the database file.
/// - passphrase: Optional encryption passphrase for secure storage.
/// - directory: Filesystem directory where the database file is stored.
/// - logStatements: Whether to log executed SQL statements (default: `false`).
/// part 'connection_offer_database.g.dart';

@DriftDatabase(
  tables: [ConnectionOffers, ConnectionContactCards, GroupConnectionOffers],
)
class ConnectionOfferDatabase extends _$ConnectionOfferDatabase {
  /// Constructs a [ConnectionOfferDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [directory]: The directory where the database file is stored.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - An instance of [ConnectionOfferDatabase].
  ConnectionOfferDatabase({
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

  /// Opens a [ConnectionOfferDatabase] from an existing [connection].
  ///
  /// Intended for migration and schema verification tests only.
  @visibleForTesting
  ConnectionOfferDatabase.forTesting(DatabaseConnection super.connection);

  /// Current schema version of the database.
  @override
  int get schemaVersion => 4;

  /// Migration strategy applied before opening the database.
  /// Ensures foreign key constraints are enforced.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // v1 connection_contact_cards stored contact fields as individual
            // columns (first_name, last_name, email, mobile, profile_pic
            // [non-null], meetingplace_identity_card_color).  v2 replaces them
            // with contact_info_json and profile_pic (nullable).
            // SQLite cannot drop or change columns in-place, so we recreate
            // the table via a temp-table rename.
            await customStatement(
              'DROP TABLE IF EXISTS connection_contact_cards_temp',
            );
            await customStatement("""
              CREATE TABLE connection_contact_cards_temp (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                connection_offer_id TEXT REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL,
                did TEXT NOT NULL,
                type TEXT NOT NULL,
                contact_info_json TEXT NOT NULL DEFAULT '{}',
                profile_pic TEXT NULL
              )
            """);
            await customStatement("""
              INSERT INTO connection_contact_cards_temp (
                id, connection_offer_id, did, type, contact_info_json, profile_pic
              )
              SELECT
                id, connection_offer_id, did, type,
                json_object(
                  'n', json_object(
                    'given', first_name,
                    'surname', last_name
                  ),
                  'email', email,
                  'mobile', mobile,
                  'color', meetingplace_identity_card_color
                ),
                profile_pic
              FROM connection_contact_cards
            """);
            await customStatement('DROP TABLE connection_contact_cards');
            await customStatement(
              '''ALTER TABLE connection_contact_cards_temp RENAME TO connection_contact_cards''',
            );
          }
          if (from < 3) {
            await migrator.addColumn(
              connectionOffers,
              connectionOffers.transport,
            );
          }
          if (from < 4) {
            // Backfill existing rows with the historical default transport
            // (didcomm = 1). The column is now NOT NULL going forward.
            await customStatement(
              'UPDATE connection_offers SET transport = 1 '
              'WHERE transport IS NULL',
            );
          }
        },
      );
}

/// Table representing connection offers.
@DataClassName('ConnectionOffer')
class ConnectionOffers extends Table {
  /// Unique identifier for the connection offer.
  TextColumn get id => text().clientDefault(const Uuid().v4)();

  /// Name of the connection offer.
  TextColumn get offerName => text()();

  /// Link to the connection offer.
  TextColumn get offerLink => text()();

  /// Description of the connection offer.
  TextColumn get offerDescription => text().nullable()();

  /// Out-of-band invitation message associated with the offer.
  TextColumn get oobInvitationMessage => text()();

  /// Mnemonic phrase for the connection offer.
  TextColumn get mnemonic => text()();

  /// Expiration date and time of the connection offer.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Creation date and time of the connection offer.
  DateTimeColumn get createdAt => dateTime()();

  /// DID of the publisher of the connection offer.
  TextColumn get publishOfferDid => text()();

  /// Type of the connection offer.
  IntColumn get type => integer().map(const _ConnectionOfferTypeConverter())();

  /// Status of the connection offer.
  IntColumn get status =>
      integer().map(const _ConnectionOfferStatusConverter())();

  /// Maximum usage count for the connection offer.
  IntColumn get maximumUsage => integer().nullable()();

  /// Indicates if the offer is owned by the local user.
  BoolColumn get ownedByMe => boolean().clientDefault(() => false)();

  /// The Mediator DID associated with the connection offer.
  TextColumn get mediatorDid => text()();

  /// Alias ID for the connection offer.
  TextColumn get aliasId => text().nullable()();

  /// ID of the outbound message related to the connection offer.
  TextColumn get outboundMessageId => text().nullable()();

  /// DID of the accepted offer.
  TextColumn get acceptOfferDid => text().nullable()();

  /// Permanent DID of the connection channel.
  TextColumn get permanentChannelDid => text().nullable()();

  /// Permanent DID of the other party in the connection channel.
  TextColumn get otherPartyPermanentChannelDid => text().nullable()();

  /// Notification token for the connection offer.
  TextColumn get notificationToken => text().nullable()();

  /// Notification token for the other party in the connection offer.
  TextColumn get otherPartyNotificationToken => text().nullable()();

  /// External reference for the connection offer.
  TextColumn get externalRef => text().nullable()();

  /// Chat transport selected by the publisher for this offer.
  /// Defaults to [ChannelTransport.didcomm] for offers persisted before
  /// per-offer transport selection existed.
  IntColumn get transport => integer()
      .map(const _ChannelTransportConverter())
      .withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing group connection offers.
@DataClassName('GroupConnectionOffer')
class GroupConnectionOffers extends Table {
  ///The connection offer ID this group connection offer is associated with.
  TextColumn get connectionOfferId => text().customConstraint(
        'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL',
      )();

  /// The member DID associated with the group connection offer.
  TextColumn get memberDid => text().nullable()();

  /// The group ID associated with the group connection offer.
  TextColumn get groupId => text()();

  ///The group's owner DID.
  TextColumn get groupOwnerDid => text().nullable()();

  /// The group's DID.
  TextColumn get groupDid => text().nullable()();

  /// Additional metadata for the group connection offer.
  TextColumn get metadata => text().nullable()();
}

/// Table representing contact cards associated with connection offers.
@DataClassName('ConnectionContactCard')
class ConnectionContactCards extends Table {
  /// Auto-incrementing ID for the contact card.
  IntColumn get id => integer().autoIncrement()();

  /// The connection offer ID this contact card is associated with.
  TextColumn get connectionOfferId => text().customConstraint(
        'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL',
      )();

  /// DID of the contact.
  TextColumn get did => text()();

  /// Type of the contact.
  TextColumn get type => text()();

  /// Flexible JSON payload for contact information.
  TextColumn get contactInfoJson => text().withDefault(const Constant('{}'))();

  /// Profile picture of the contact.
  TextColumn get profilePic => text().nullable()();
}

extension _ConnectionOfferTypeValue on ConnectionOfferType {
  int get value {
    switch (this) {
      case ConnectionOfferType.meetingPlaceInvitation:
        return 1;
      case ConnectionOfferType.meetingPlaceOutreachInvitation:
        return 2;
    }
  }
}

class _ConnectionOfferTypeConverter
    extends TypeConverter<ConnectionOfferType, int> {
  const _ConnectionOfferTypeConverter();

  @override
  ConnectionOfferType fromSql(int fromDb) {
    return ConnectionOfferType.values.firstWhere(
      (type) => type.value == fromDb,
    );
  }

  @override
  int toSql(ConnectionOfferType value) {
    return value.value;
  }
}

extension _ConnectionOfferStatusValue on ConnectionOfferStatus {
  int get value {
    switch (this) {
      case ConnectionOfferStatus.published:
        return 1;
      case ConnectionOfferStatus.finalised:
        return 2;
      case ConnectionOfferStatus.accepted:
        return 3;
      case ConnectionOfferStatus.channelInaugurated:
        return 4;
      case ConnectionOfferStatus.deleted:
        return 5;
    }
  }
}

class _ConnectionOfferStatusConverter
    extends TypeConverter<ConnectionOfferStatus, int> {
  const _ConnectionOfferStatusConverter();

  @override
  ConnectionOfferStatus fromSql(int fromDb) {
    return ConnectionOfferStatus.values.firstWhere(
      (type) => type.value == fromDb,
    );
  }

  @override
  int toSql(ConnectionOfferStatus value) {
    return value.value;
  }
}

extension _ChannelTransportValue on ChannelTransport {
  int get value {
    switch (this) {
      case ChannelTransport.didcomm:
        return 1;
      case ChannelTransport.matrix:
        return 2;
    }
  }
}

class _ChannelTransportConverter extends TypeConverter<ChannelTransport, int> {
  const _ChannelTransportConverter();

  @override
  ChannelTransport fromSql(int fromDb) {
    return ChannelTransport.values.firstWhere((t) => t.value == fromDb);
  }

  @override
  int toSql(ChannelTransport value) {
    return value.value;
  }
}
