import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
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
  ///  (default is false).
  ChannelDatabase({
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

  /// The current schema version of the database.
  @override
  int get schemaVersion => 1;

  /// Migration strategy to handle database version upgrades.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Table representing chat channels.
@DataClassName('Channel')
@TableIndex(name: 'offer_link', columns: {#offerLink})
class Channels extends Table {
  TextColumn get id => text().clientDefault(const Uuid().v4)();
  TextColumn get publishOfferDid => text()();
  TextColumn get mediatorDid => text()();
  TextColumn get offerLink => text()();
  IntColumn get status => integer().map(const _ChannelStatusConverter())();
  IntColumn get type => integer().map(const _ChannelTypeConverter())();
  TextColumn get outboundMessageId => text().nullable()();
  TextColumn get acceptOfferDid => text().nullable()();
  TextColumn get permanentChannelDid => text().nullable()();
  TextColumn get otherPartyPermanentChannelDid => text().nullable()();
  TextColumn get notificationToken => text().nullable()();
  TextColumn get otherPartyNotificationToken => text().nullable()();
  TextColumn get externalRef => text().nullable()();
  IntColumn get seqNo => integer()();
  DateTimeColumn get messageSyncMarker => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing contact cards associated with chat channels.
@DataClassName('ChannelContactCard')
class ChannelContactCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get channelId => text().customConstraint(
        'REFERENCES channels(id) ON DELETE CASCADE NOT NULL',
      )();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()();
  TextColumn get mobile => text()();
  TextColumn get profilePic => text()();
  TextColumn get meetingplaceIdentityCardColor => text()();
  IntColumn get cardType => integer().map(const _VCardTypeConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId, cardType},
      ];
}

/// Enum representing the type of VCard.
enum VCardType {
  mine(1),
  other(2);

  const VCardType(this.value);

  final int value;
}

class _VCardTypeConverter extends TypeConverter<VCardType, int> {
  const _VCardTypeConverter();

  @override
  VCardType fromSql(int fromDb) {
    return VCardType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(VCardType value) {
    return value.value;
  }
}

extension _ChannelStatusValue on ChannelStatus {
  int get value {
    switch (this) {
      case ChannelStatus.approved:
        return 1;
      case ChannelStatus.inaugaurated:
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
