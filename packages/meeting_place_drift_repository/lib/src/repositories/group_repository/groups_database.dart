import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

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

  /// Opens a [GroupsDatabase] from an existing [connection].
  ///
  /// Intended for migration and schema verification tests only.
  @visibleForTesting
  GroupsDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // v1 group_members stored contact fields as individual columns
            // (first_name, last_name, email, mobile, profile_pic [non-null],
            // meetingplace_identity_card_color).  v2 replaces them with
            // contact_info_json and profile_pic (nullable).
            // SQLite cannot drop or change columns in-place, so we recreate
            // the table via a temp-table rename.
            await customStatement('DROP TABLE IF EXISTS group_members_temp');
            await customStatement("""
              CREATE TABLE group_members_temp (
                group_id TEXT REFERENCES meeting_place_groups(id) ON DELETE CASCADE NOT NULL,
                member_did TEXT NOT NULL,
                group_owner_did TEXT NULL,
                group_did TEXT NULL,
                metadata TEXT NULL,
                accept_offer_as_did TEXT NULL,
                date_added TEXT NOT NULL,
                public_key TEXT NOT NULL,
                membership_type INTEGER NOT NULL,
                peer_profile_hash TEXT NULL,
                status INTEGER NOT NULL,
                identity_did TEXT NOT NULL,
                type TEXT NOT NULL,
                contact_info_json TEXT NOT NULL DEFAULT '{}',
                profile_pic TEXT NULL
              )
            """);
            await customStatement("""
              INSERT INTO group_members_temp (
                group_id, member_did, group_owner_did, group_did, metadata,
                accept_offer_as_did, date_added, public_key, membership_type,
                peer_profile_hash, status, identity_did, type,
                contact_info_json, profile_pic
              )
              SELECT
                group_id, member_did, group_owner_did, group_did, metadata,
                accept_offer_as_did, date_added, public_key, membership_type,
                peer_profile_hash, status, identity_did, type,
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
              FROM group_members
            """);
            await customStatement('DROP TABLE group_members');
            await customStatement(
              'ALTER TABLE group_members_temp RENAME TO group_members',
            );
          }
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

  /// Flexible JSON payload for contact information.
  TextColumn get contactInfoJson => text().withDefault(const Constant('{}'))();

  /// Profile picture of the contact.
  TextColumn get profilePic => text().nullable()();
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
