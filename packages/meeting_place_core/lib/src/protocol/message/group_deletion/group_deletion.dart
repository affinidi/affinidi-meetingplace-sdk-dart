import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'group_deletion_body.dart';

class GroupDeletion {
  factory GroupDeletion.create({required String groupId}) {
    return GroupDeletion(
      id: const Uuid().v4(),
      body: GroupDeletionBody(groupId: groupId),
    );
  }

  factory GroupDeletion.fromPlainTextMessage(PlainTextMessage message) {
    return GroupDeletion(
      id: message.id,
      body: GroupDeletionBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  GroupDeletion({required this.id, required this.body, DateTime? createdTime})
    : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final GroupDeletionBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.groupDeletion.value),
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
