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
  ConnectionOfferDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) : super(
          openConnection(
            databaseName: databaseName,
            passphrase: passphrase,
            directory: directory,
            logStatements: logStatements,
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

@DataClassName('ConnectionOffer')
class ConnectionOffers extends Table {
  TextColumn get id => text().clientDefault(const Uuid().v4)();
  TextColumn get offerName => text()();
  TextColumn get offerLink => text()();
  TextColumn get offerDescription => text().nullable()();
  TextColumn get oobInvitationMessage => text()();
  TextColumn get mnemonic => text()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get publishOfferDid => text()();
  IntColumn get type => integer().map(const _ConnectionOfferTypeConverter())();
  IntColumn get status =>
      integer().map(const _ConnectionOfferStatusConverter())();
  IntColumn get maximumUsage => integer().nullable()();
  BoolColumn get ownedByMe => boolean().clientDefault(() => false)();
  TextColumn get mediatorDid => text()();
  TextColumn get aliasId => text().nullable()();
  TextColumn get outboundMessageId => text().nullable()();
  TextColumn get acceptOfferDid => text().nullable()();
  TextColumn get permanentChannelDid => text().nullable()();
  TextColumn get otherPartyPermanentChannelDid => text().nullable()();
  TextColumn get notificationToken => text().nullable()();
  TextColumn get otherPartyNotificationToken => text().nullable()();
  TextColumn get externalRef => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GroupConnectionOffer')
class GroupConnectionOffers extends Table {
  TextColumn get connectionOfferId => text().customConstraint(
        'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL',
      )();
  TextColumn get memberDid => text().nullable()();
  TextColumn get groupId => text()();
  TextColumn get groupOwnerDid => text().nullable()();
  TextColumn get groupDid => text().nullable()();
  TextColumn get metadata => text().nullable()();
}

@DataClassName('ConnectionContactCard')
class ConnectionContactCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get connectionOfferId => text().customConstraint(
        'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL',
      )();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()();
  TextColumn get mobile => text()();
  TextColumn get profilePic => text()();
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
