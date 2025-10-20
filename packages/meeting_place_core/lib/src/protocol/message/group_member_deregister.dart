import '../../../meeting_place_core.dart';
import 'package:uuid/uuid.dart';

class GroupMemberDeregistered extends PlainTextMessage {
  GroupMemberDeregistered({
    required super.id,
    required String groupId,
    required String memberDid,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.groupMemberDeregistered.value),
          body: {'groupId': groupId, 'memberDid': memberDid},
        );

  factory GroupMemberDeregistered.create({
    required String groupId,
    required String memberDid,
  }) {
    return GroupMemberDeregistered(
      id: const Uuid().v4(),
      groupId: groupId,
      memberDid: memberDid,
    );
  }
}
