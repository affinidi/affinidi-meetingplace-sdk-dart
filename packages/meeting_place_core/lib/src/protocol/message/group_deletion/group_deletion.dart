import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';
import '../../meeting_place_protocol.dart';
import 'group_deletion_body.dart';

class GroupDeletion extends PlainTextMessage {
  GroupDeletion({required super.id, required String groupId})
      : super(
          type: Uri.parse(MeetingPlaceProtocol.groupDeletion.value),
          body: GroupDeletionBody(groupId: groupId).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory GroupDeletion.create({required String groupId}) {
    return GroupDeletion(id: const Uuid().v4(), groupId: groupId);
  }
}
