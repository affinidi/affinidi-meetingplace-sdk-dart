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
@DriftDatabase(tables: [MpxGroups, GroupMembers])
class GroupsDatabase extends _$GroupsDatabase {
  GroupsDatabase({
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
@DataClassName('MpxGroup')
class MpxGroups extends Table {
  TextColumn get id => text()();
  TextColumn get did => text()();
  TextColumn get offerLink => text()();
  IntColumn get status => integer().map(const _GroupStatusConverter())();
  DateTimeColumn get created => dateTime()();

  TextColumn get groupKeyPair => text().nullable()();
  TextColumn get publicKey => text().nullable()();
  TextColumn get ownerDid => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing members of groups in the database.
@DataClassName('GroupMember')
class GroupMembers extends Table {
  TextColumn get groupId => text().customConstraint(
        'REFERENCES mpx_groups(id) ON DELETE CASCADE NOT NULL',
      )();
  TextColumn get memberDid => text()();
  TextColumn get groupOwnerDid => text().nullable()();
  TextColumn get groupDid => text().nullable()();
  TextColumn get metadata => text().nullable()();

  TextColumn get acceptOfferAsDid => text().nullable()();
  DateTimeColumn get dateAdded => dateTime().clientDefault(clock.now)();
  TextColumn get publicKey => text()();
  IntColumn get membershipType =>
      integer().map(const _GroupMembershipTypeConverter())();
  TextColumn get peerProfileHash => text().nullable()();
  IntColumn get status => integer().map(const _GroupMemberStatusConverter())();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()();
  TextColumn get mobile => text()();
  TextColumn get profilePic => text()();
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
