import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
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

  /// Current schema version of the database.
  @override
  int get schemaVersion => 1;

  /// Migration strategy applied before opening the database.
  /// Ensures foreign key constraints are enforced.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
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

  /// First name of the contact.
  TextColumn get firstName => text()();

  /// Last name of the contact.
  TextColumn get lastName => text()();

  /// Email address of the contact.
  TextColumn get email => text()();

  /// Mobile number of the contact.
  TextColumn get mobile => text()();

  /// Company of the contact.
  TextColumn get company => text()();

  /// Position of the contact.
  TextColumn get position => text()();

  /// Social information of the contact.
  TextColumn get social => text()();

  /// Website of the contact.
  TextColumn get website => text()();

  /// Profile picture of the contact.
  TextColumn get profilePic => text()();

  /// MeetingPlace identity card color of the contact.
  TextColumn get meetingplaceIdentityCardColor => text()();
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

extension ConnectionOfferStatusValue on ConnectionOfferStatus {
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
