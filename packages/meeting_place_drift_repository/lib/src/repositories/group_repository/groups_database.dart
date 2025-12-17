import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../database/database_platform.dart';

part 'groups_database.g.dart';

/// [GroupsDatabase] defines the Drift (SQLite) database
/// for managing group-related data.
///
/// This database is encrypted with a passphrase and stored
/// in the provided directory.
///
/// ### Parameters:
/// - databaseName: Logical name of the database file.
/// - passphrase: Encryption passphrase for secure storage.
/// - directory: Directory where the database file is stored.
/// - logStatement: Enables SQL query logging when `true` (default: `false`).
@DriftDatabase(tables: [MeetingPlaceGroups, GroupMembers])
class GroupsDatabase extends _$GroupsDatabase {
  /// Constructs a [GroupsDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [directory]: The directory where the database file is stored.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - An instance of [GroupsDatabase].
  GroupsDatabase({
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

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Table representing groups in the database.
@DataClassName('MeetingPlaceGroup')
class MeetingPlaceGroups extends Table {
  /// The unique identifier for the group.
  TextColumn get id => text()();

  /// The DID of the group.
  TextColumn get did => text()();

  /// The offer link associated with the group.
  TextColumn get offerLink => text()();

  /// The status of the group.
  IntColumn get status => integer().map(const _GroupStatusConverter())();

  /// The date and time when the group was created.
  DateTimeColumn get created => dateTime()();

  /// The key pair associated with the group.
  TextColumn get groupKeyPair => text().nullable()();

  /// The public key of the group.
  TextColumn get publicKey => text().nullable()();

  /// The DID of the owner of the group.
  TextColumn get ownerDid => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing members of groups in the database.
@DataClassName('GroupMember')
class GroupMembers extends Table {
  /// The group id of the member.
  TextColumn get groupId => text().customConstraint(
        'REFERENCES meeting_place_groups(id) ON DELETE CASCADE NOT NULL',
      )();

  /// The DID of the group member.
  TextColumn get memberDid => text()();

  /// The DID of the group owner.
  TextColumn get groupOwnerDid => text().nullable()();

  /// The DID of the group.
  TextColumn get groupDid => text().nullable()();

  /// Additional metadata for the group member.
  TextColumn get metadata => text().nullable()();

  /// The accept offer as DID of the group member.
  TextColumn get acceptOfferAsDid => text().nullable()();

  /// The date and time when the member was added to the group.
  DateTimeColumn get dateAdded => dateTime().clientDefault(clock.now)();

  /// The public key of the group member.
  TextColumn get publicKey => text()();

  /// The membership type of the group member.
  IntColumn get membershipType =>
      integer().map(const _GroupMembershipTypeConverter())();

  /// The profile hash of the group member.
  TextColumn get peerProfileHash => text().nullable()();

  /// The status of the group member.
  IntColumn get status => integer().map(const _GroupMemberStatusConverter())();

  /// DID of the contact.
  TextColumn get identityDid => text()();

  /// Type of the contact.
  TextColumn get type => text()();

  // Schema of the contact card.
  TextColumn get schema => text()();

  /// The first name of the group member.
  TextColumn get firstName => text()();

  /// The last name of the group member.
  TextColumn get lastName => text()();

  /// The email of the group member.
  TextColumn get email => text()();

  /// The mobile number of the group member.
  TextColumn get mobile => text()();

  /// The profile picture of the group member.
  TextColumn get profilePic => text()();

  /// The MeetingPlace identity card color of the group member.
  TextColumn get meetingplaceIdentityCardColor => text()();
}

extension _GroupStatusValue on GroupStatus {
  int get value {
    switch (this) {
      case GroupStatus.created:
        return 1;
      case GroupStatus.deleted:
        return 2;
    }
  }
}

class _GroupStatusConverter extends TypeConverter<GroupStatus, int> {
  const _GroupStatusConverter();

  @override
  GroupStatus fromSql(int fromDb) {
    return GroupStatus.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(GroupStatus value) {
    return value.value;
  }
}

extension _GroupMemberStatusValue on GroupMemberStatus {
  int get value {
    switch (this) {
      case GroupMemberStatus.pendingApproval:
        return 1;
      case GroupMemberStatus.pendingInauguration:
        return 2;
      case GroupMemberStatus.approved:
        return 3;
      case GroupMemberStatus.error:
        return 4;
      case GroupMemberStatus.deleted:
        return 5;
      case GroupMemberStatus.rejected:
        return 6;
    }
  }
}

class _GroupMemberStatusConverter
    extends TypeConverter<GroupMemberStatus, int> {
  const _GroupMemberStatusConverter();

  @override
  GroupMemberStatus fromSql(int fromDb) {
    return GroupMemberStatus.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(GroupMemberStatus value) {
    return value.value;
  }
}

extension _GroupMembershipTypeValue on GroupMembershipType {
  int get value {
    switch (this) {
      case GroupMembershipType.admin:
        return 1;
      case GroupMembershipType.member:
        return 2;
    }
  }
}

class _GroupMembershipTypeConverter
    extends TypeConverter<GroupMembershipType, int> {
  const _GroupMembershipTypeConverter();

  @override
  GroupMembershipType fromSql(int fromDb) {
    return GroupMembershipType.values.firstWhere(
      (type) => type.value == fromDb,
    );
  }

  @override
  int toSql(GroupMembershipType value) {
    return value.value;
  }
}
