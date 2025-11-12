import '../../../meeting_place_core.dart';
import 'package:uuid/uuid.dart';

class GroupDeletion extends PlainTextMessage {
  GroupDeletion({required super.id, required String groupId})
      : super(
          type: Uri.parse(MeetingPlaceProtocol.groupDeletion.value),
          body: {'groupId': groupId},
          createdTime: DateTime.now().toUtc(),
        );

  factory GroupDeletion.create({required String groupId}) {
    return GroupDeletion(id: const Uuid().v4(), groupId: groupId);
  }
}
