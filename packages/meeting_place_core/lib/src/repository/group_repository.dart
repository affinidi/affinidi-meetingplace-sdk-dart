import '../../meeting_place_core.dart';

abstract interface class GroupRepository {
  Future<void> createGroup(Group group);
  Future<void> updateGroup(Group group);

  Future<Group?> getGroupById(String groupId);
  Future<Group?> getGroupByOfferLink(String offerLink);
  Future<void> removeGroup(Group group);
}
