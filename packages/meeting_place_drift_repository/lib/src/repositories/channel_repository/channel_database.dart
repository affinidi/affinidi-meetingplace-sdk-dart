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

  /// First name of the contact.
  TextColumn get firstName => text()();

  /// Last name of the contact.
  TextColumn get lastName => text()();

  /// Email address of the contact.
  TextColumn get email => text()();

  /// Mobile number of the contact.
  TextColumn get mobile => text()();

  /// Profile picture of the contact.
  TextColumn get profilePic => text()();

  /// Identity card color of the contact.
  TextColumn get meetingplaceIdentityCardColor => text()();

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
