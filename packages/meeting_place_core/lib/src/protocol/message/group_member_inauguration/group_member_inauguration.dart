import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../protocol.dart';
import 'group_member_inauguration_body.dart';
import 'group_member_inauguration_member.dart';

class GroupMemberInauguration {
  factory GroupMemberInauguration.create({
    required String from,
    required List<String> to,
    required String memberDid,
    required String groupDid,
    required String groupId,
    required String groupPublicKey,
    required List<String> adminDids,
    required List<GroupMemberInaugurationMember> members,
  }) {
    return GroupMemberInauguration(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: GroupMemberInaugurationBody(
        memberDid: memberDid,
        groupDid: groupDid,
        groupId: groupId,
        groupPublicKey: groupPublicKey,
        adminDids: adminDids,
        members: members,
      ),
    );
  }

  factory GroupMemberInauguration.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    ContactCard? contactCard;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      final base64 = message.attachments!.first.data?.base64;
      if (base64 != null) {
        contactCard = ContactCard.fromBase64(base64);
      }
    }
    return GroupMemberInauguration(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: GroupMemberInaugurationBody.fromJson(message.body!),
      contactCard: contactCard,
      createdTime: message.createdTime,
    );
  }

  GroupMemberInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.contactCard,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final GroupMemberInaugurationBody body;
  final ContactCard? contactCard;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.groupMemberInauguration.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: contactCard == null
          ? null
          : [
              Attachment(
                id: const Uuid().v4(),
                format: AttachmentFormat.contactCard.value,
                mediaType: AttachmentMediaType.textContactCard.value,
                description: 'Contact card info',
                data: AttachmentData(base64: contactCard!.toBase64()),
              ),
            ],
    );
  }
}
