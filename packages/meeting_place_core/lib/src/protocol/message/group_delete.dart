import 'package:uuid/uuid.dart';

import '../../../meeting_place_core.dart';

class GroupDelete extends PlainTextMessage {
  GroupDelete({required super.id, required String groupId})
      : super(
          type: Uri.parse(MeetingPlaceProtocol.groupDeleted.value),
          body: {'groupId': groupId},
          createdTime: DateTime.now().toUtc(),
        );

  factory GroupDelete.create({required String groupId}) {
    return GroupDelete(id: const Uuid().v4(), groupId: groupId);
  }
}
