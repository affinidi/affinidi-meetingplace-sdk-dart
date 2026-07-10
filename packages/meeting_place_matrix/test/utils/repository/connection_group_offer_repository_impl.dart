import 'dart:convert';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../storage/storage.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({required Storage storage}) : _storage = storage;

  static const String groupPrefix = 'group_';
  static const String connectionGroupRelationPrefix = 'connection_group_rel_';
  final Storage _storage;

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

    if (groupId == null) {
      return null;
    }

    return getGroupById(groupId);
  }

  @override
  Future<void> removeGroup(Group group) {
    return _storage.remove('$groupPrefix${group.id}');
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
