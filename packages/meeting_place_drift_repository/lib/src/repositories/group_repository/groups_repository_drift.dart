import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;

import '../../exceptions/meeting_place_core_repository_error_code.dart';
import '../../exceptions/meeting_place_core_repository_exception.dart';
import '../../extensions/vcard_extensions.dart';
import 'groups_database.dart' as db;

/// Repository implementation for persisting and retrieving
/// [model.Group] entities using a Drift-backed [db.GroupsDatabase].
///
/// This class encapsulates all operations for groups
/// and their associated members. It ensures that group and
/// member data remain consistent by wrapping operations in
/// database transactions when needed.
class GroupsRepositoryDrift implements model.GroupRepository {
  /// Constructs a [GroupsRepositoryDrift] with the provided
  /// [db.GroupsDatabase] instance.
  ///
  /// **Parameters:**
  /// - [database]: The Drift database instance for group data.
  ///
  /// **Returns:**
  /// - An instance of [GroupsRepositoryDrift].
  GroupsRepositoryDrift({required db.GroupsDatabase database})
      : _database = database;

  final db.GroupsDatabase _database;

  /// Creates a new [model.Group] in the database along with its members.
  ///
  /// **Parameters:**
  /// - [group]: The [model.Group] to be created.
  ///
  /// **Returns:**
  /// - A [Future] that completes when the group has been created.
  ///
  /// **Throws:**
  /// - [MeetingPlaceCoreRepositoryException] if the group could not be created.
  @override
  Future<void> createGroup(model.Group group) async {
    await _database.transaction(() async {
      await _database.into(_database.meetingPlaceGroups).insert(
            db.MeetingPlaceGroupsCompanion(
              id: Value(group.id),
              did: Value(group.did),
              offerLink: Value(group.offerLink),
              status: Value(group.status),
              created: Value(group.created),
              publicKey: Value(group.publicKey),
              ownerDid: Value(group.ownerDid),
            ),
          );

      final groupMembers = group.members.map((member) {
        final vCard = member.vCard;
        return db.GroupMembersCompanion.insert(
          groupId: group.id,
          memberDid: member.did,
          dateAdded: Value(member.dateAdded),
          publicKey: member.publicKey,
          membershipType: member.membershipType,
          status: member.status,
          firstName: vCard.firstName,
          lastName: vCard.lastName,
          email: vCard.email,
          mobile: vCard.mobile,
          profilePic: vCard.profilePic,
          meetingplaceIdentityCardColor: vCard.meetingplaceIdentityCardColor,
        );
      });

      await _database.batch((batch) {
        batch.insertAll(_database.groupMembers, groupMembers);
      });

      final newGroup = await (_database.select(
        _database.meetingPlaceGroups,
      )..where((filter) => filter.id.equals(group.id)))
          .getSingleOrNull();
      if (newGroup == null) {
        throw MeetingPlaceCoreRepositoryException(
          'Group not found',
          code: MeetingPlaceCoreRepositoryErrorCode.missingGroup,
        );
      }
    });
  }

  /// Retrieves a [model.Group] by its unique [groupId].
  ///
  /// - [groupId]: The identifier of the group to fetch.
  ///
  /// Returns the [model.Group] including its member list, or `null`
  /// if no group with the given ID exists.
  @override
  Future<model.Group?> getGroupById(String groupId) async {
    final results = await Future.wait([
      (_database.select(
        _database.meetingPlaceGroups,
      )..where((g) => g.id.equals(groupId)))
          .getSingleOrNull(),
      (_database.select(
        _database.groupMembers,
      )..where((gm) => gm.groupId.equals(groupId)))
          .get(),
    ]);

    final group = results[0] as db.MeetingPlaceGroup?;
    if (group == null) return null;

    final groupMembers = results[1] as List<db.GroupMember>;

    return _GroupMapper.fromDatabaseRecords(group, groupMembers);
  }

  /// Retrieves a [model.Group] by its invitation [offerLink].
  ///
  /// - [offerLink]: A unique string that represents the group's
  ///   invitation link.
  ///
  /// Returns the [model.Group], or `null` if no matching group exists.
  @override
  Future<model.Group?> getGroupByOfferLink(String offerLink) async {
    final group = await (_database.select(
      _database.meetingPlaceGroups,
    )..where((g) => g.offerLink.equals(offerLink)))
        .getSingleOrNull();
    if (group == null) return null;

    return getGroupById(group.id);
  }

  /// Deletes a [model.Group] from the database.
  ///
  /// - [group]: The [model.Group] to remove. Only the group's ID
  ///   is required for deletion.
  @override
  Future<void> removeGroup(model.Group group) async {
    await (_database.delete(
      _database.meetingPlaceGroups,
    )..where((filter) => filter.id.equals(group.id)))
        .go();
  }

  /// Updates an existing [model.Group] and replaces its members.
  ///
  /// - [group]: The [model.Group] object with updated metadata and
  ///   member information.
  ///
  /// Throws [MeetingPlaceCoreRepositoryException] if the group does not exist
  /// in the database.
  @override
  Future<void> updateGroup(model.Group group) async {
    await _database.transaction(() async {
      final query = _database.select(_database.meetingPlaceGroups)
        ..where((c) => _database.meetingPlaceGroups.id.equals(group.id));
      final results = await query.getSingleOrNull();
      if (results == null) {
        throw MeetingPlaceCoreRepositoryException(
          'Trying to update a group that does not exists',
          code: MeetingPlaceCoreRepositoryErrorCode.missingGroup,
        );
      }

      final groupId = results.id;
      await (_database.update(
        _database.meetingPlaceGroups,
      )..where((c) => c.id.equals(groupId)))
          .write(
        db.MeetingPlaceGroupsCompanion(
          id: Value(group.id),
          did: Value(group.did),
          status: Value(group.status),
          offerLink: Value(group.offerLink),
          created: Value(group.created),
          publicKey: Value(group.publicKey),
          ownerDid: Value(group.ownerDid),
        ),
      );

      await (_database.delete(
        _database.groupMembers,
      )..where((a) => a.groupId.equals(groupId)))
          .go();

      final groupMembersCompanions = group.members.map((member) {
        final vCard = member.vCard;
        return db.GroupMembersCompanion.insert(
          groupId: group.id,
          memberDid: member.did,
          dateAdded: Value(member.dateAdded),
          publicKey: member.publicKey,
          membershipType: member.membershipType,
          status: member.status,
          firstName: vCard.firstName,
          lastName: vCard.lastName,
          email: vCard.email,
          mobile: vCard.mobile,
          profilePic: vCard.profilePic,
          meetingplaceIdentityCardColor: vCard.meetingplaceIdentityCardColor,
        );
      });

      await _database.batch((batch) {
        batch.insertAll(_database.groupMembers, groupMembersCompanions);
      });
    });
  }
}

class _GroupMapper {
  static model.Group fromDatabaseRecords(
    db.MeetingPlaceGroup group,
    List<db.GroupMember> groupMembers,
  ) {
    return model.Group(
      id: group.id,
      did: group.did,
      status: group.status,
      offerLink: group.offerLink,
      members:
          groupMembers.map(_GroupMemberMapper.fromDatabaseRecords).toList(),
      created: group.created,
      ownerDid: group.ownerDid,
      publicKey: group.publicKey,
    );
  }
}

class _GroupMemberMapper {
  static model.GroupMember fromDatabaseRecords(db.GroupMember groupMember) {
    return model.GroupMember(
      did: groupMember.memberDid,
      dateAdded: groupMember.dateAdded,
      status: groupMember.status,
      membershipType: groupMember.membershipType,
      vCard: _makeVCardFromContactCard(groupMember),
      publicKey: groupMember.publicKey,
    );
  }

  static model.ContactCard _makeVCardFromContactCard(
      db.GroupMember groupMember) {
    final vCard = model.ContactCard(values: {});
    vCard.firstName = groupMember.firstName;
    vCard.lastName = groupMember.lastName;
    vCard.email = groupMember.email;
    vCard.mobile = groupMember.mobile;
    vCard.profilePic = groupMember.profilePic;
    vCard.meetingplaceIdentityCardColor =
        groupMember.meetingplaceIdentityCardColor;

    return vCard;
  }
}
