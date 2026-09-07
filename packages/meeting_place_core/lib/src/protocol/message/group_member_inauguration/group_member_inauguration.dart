import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../protocol.dart';
import 'group_member_inauguration_body.dart';
import 'group_member_inauguration_member.dart';

/// A group-member-inauguration DIDComm message, sent to inaugurate a new
/// member into a group and share the group's current membership.
class GroupMemberInauguration {
  /// Creates a new [GroupMemberInauguration] message with a generated [id].
  factory GroupMemberInauguration.create({
    required String from,
    required List<String> to,
    required String memberDid,
    required String groupDid,
    required String groupId,
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
        adminDids: adminDids,
        members: members,
      ),
    );
  }

  /// Creates a [GroupMemberInauguration] from a decoded [PlainTextMessage].
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

  /// Creates a [GroupMemberInauguration] from its constituent message
  /// fields.
  GroupMemberInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.contactCard,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  /// The DIDComm message id.
  final String id;

  /// The DID of the sender.
  final String from;

  /// The DIDs of the message recipients.
  final List<String> to;

  /// The message body carrying the group's membership and admin DIDs.
  final GroupMemberInaugurationBody body;

  /// The new member's contact card, if shared.
  final ContactCard? contactCard;

  /// When this message was created.
  final DateTime createdTime;

  /// Converts this message to a [PlainTextMessage] for transport.
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
