import '../../../meeting_place_core.dart';
import 'package:uuid/uuid.dart';

class GroupMemberDeregistration extends PlainTextMessage {
  GroupMemberDeregistration({
    required super.id,
    required String groupId,
    required String memberDid,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.groupMemberDeregistration.value),
          body: {'groupId': groupId, 'memberDid': memberDid},
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
