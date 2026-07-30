import 'dart:convert';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../storage.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({required InMemoryStorage storage}) : _storage = storage;
  static const String groupPrefix = 'group_';
  static const String connectionGroupRelationPrefix = 'connection_group_rel_';
  final InMemoryStorage _storage;

  @override
  Future<void> createGroup(Group group) async {
    await _storage.put('$groupPrefix${group.id}', json.encode(group.toJson()));

    await _saveGroupToOfferLink(group.id, group.did, group.offerLink);
  }

  @override
  Future<void> updateGroup(Group group) async {
    await _storage.put('$groupPrefix${group.id}', json.encode(group.toJson()));

    await _saveGroupToOfferLink(group.id, group.did, group.offerLink);
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    final group = await _storage.get<String>('$groupPrefix$groupId');
    if (group == null) return null;

    return Group.fromJson(jsonDecode(group) as Map<String, dynamic>);
  }

  @override
  Future<Group?> getGroupByOfferLink(String offerLink) async {
    final groupId = await _storage.get<String>(
      '$connectionGroupRelationPrefix$offerLink',
    );
    if (groupId == null) return null;

    return getGroupById(groupId);
  }

  @override
  Future<void> removeGroup(Group group) {
    return _storage.remove('$groupPrefix${group.id}');
  }

  @override
  Future<void> addMemberIfAbsent(String groupId, GroupMember member) async {
    final group = await getGroupById(groupId);
    if (group == null) return;
    final alreadyPresent = group.members.any((m) => m.did == member.did);
    if (alreadyPresent) return;
    group.members.add(member);
    await updateGroup(group);
  }

  @override
  Future<void> updateMemberStatus(
    String groupId,
    String memberDid,
    GroupMemberStatus status,
  ) async {
    final group = await getGroupById(groupId);
    if (group == null) return;
    for (final m in group.members) {
      if (m.did == memberDid) {
        m.status = status;
        break;
      }
    }
    await updateGroup(group);
  }

  Future<void> _saveGroupToOfferLink(
    String groupId,
    String groupDid,
    String offerLink,
  ) async {
    await _storage.put('$connectionGroupRelationPrefix$offerLink', groupId);
    await _storage.put('$connectionGroupRelationPrefix$groupDid', offerLink);
  }
}
