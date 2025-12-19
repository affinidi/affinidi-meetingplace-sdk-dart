import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'group_member_deregistration_body.dart';

class GroupMemberDeregistration {
  factory GroupMemberDeregistration.create({
    required String groupId,
    required String memberDid,
  }) {
    return GroupMemberDeregistration(
      id: const Uuid().v4(),
      body: GroupMemberDeregistrationBody(
        groupId: groupId,
        memberDid: memberDid,
      ),
    );
  }

  factory GroupMemberDeregistration.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return GroupMemberDeregistration(
      id: message.id,
      body: GroupMemberDeregistrationBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  GroupMemberDeregistration({
    required this.id,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final GroupMemberDeregistrationBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.groupMemberDeregistration.value),
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
