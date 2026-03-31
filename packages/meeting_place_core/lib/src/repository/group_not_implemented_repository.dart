import '../../meeting_place_core.dart';

class GroupNotImplementedRepository implements GroupRepository {
  const GroupNotImplementedRepository();

  @override
  Future<Group?> getGroupById(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<Group?> getGroupByOfferLink(String offerLink) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeGroup(Group group) {
    throw UnimplementedError();
  }

  @override
  Future<void> createGroup(Group group) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateGroup(Group group) {
    throw UnimplementedError();
  }
}
