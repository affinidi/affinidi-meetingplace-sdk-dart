import '../../meeting_place_core.dart';

/// Persists and retrieves [Group] entities and their members.
///
/// Implementations back the SDK's group state with durable storage (for
/// example a Drift/SQLite database) so groups survive across app restarts.
abstract interface class GroupRepository {
  /// Persists a new [group], including its members.
  Future<void> createGroup(Group group);

  /// Replaces the stored group matching [group]'s id, including its member
  /// list, with [group].
  ///
  /// Implementations are expected to throw if no group with that id exists
  /// yet.
  Future<void> updateGroup(Group group);

  /// Finds a group by its [groupId], including its members.
  ///
  /// Returns `null` if no matching group exists.
  Future<Group?> findGroupById(String groupId);

  /// Finds a group by its invitation [offerLink].
  ///
  /// Returns `null` if no matching group exists.
  Future<Group?> findGroupByOfferLink(String offerLink);

  /// Deletes the stored group matching [group]'s id, if any.
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

  /// Atomically deletes the single member row identified by
  /// `(groupId, memberDid)`. A no-op when no such row exists. Other member
  /// rows are untouched.
  ///
  /// Unlike [updateGroup], which replaces the entire member list, this method
  /// is safe to call concurrently with other single-row mutations.
  Future<void> removeMember(String groupId, String memberDid);
}
