import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';
import '../../meeting_place_protocol.dart';
import 'group_member_deregistration_body.dart';

class GroupMemberDeregistration extends PlainTextMessage {
  GroupMemberDeregistration({
    required super.id,
    required String groupId,
    required String memberDid,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.groupMemberDeregistration.value),
          body: GroupMemberDeregistrationBody(
                  groupId: groupId, memberDid: memberDid)
              .toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory GroupMemberDeregistration.create({
    required String groupId,
    required String memberDid,
  }) {
    return GroupMemberDeregistration(
      id: const Uuid().v4(),
      groupId: groupId,
      memberDid: memberDid,
    );
  }
}
