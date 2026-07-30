import '../../meeting_place_core.dart';

abstract interface class GroupRepository {
  Future<void> createGroup(Group group);
  Future<void> updateGroup(Group group);

  Future<Group?> getGroupById(String groupId);
  Future<Group?> getGroupByOfferLink(String offerLink);
  Future<void> removeGroup(Group group);

  /// Atomically inserts [member] into the group identified by [groupId] only
  /// if no row with the same `(groupId, member.did)` pair already exists.
  ///
  /// This is idempotent: repeated calls with the same arguments are safe and
  /// result in at most one row being written. Concurrent callers therefore
  /// cannot produce duplicate member entries or clobber each other's writes.
  Future<void> addMemberIfAbsent(String groupId, GroupMember member);

  /// Atomically updates the [status] of the single member row identified by
  /// `(groupId, memberDid)` without touching any other member rows.
  ///
  /// Unlike [updateGroup], which replaces the entire member list, this method
  /// is safe to call concurrently with other single-row mutations.
  Future<void> updateMemberStatus(
    String groupId,
    String memberDid,
    GroupMemberStatus status,
  );
}
