import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../attachment/attachment_format.dart';
import '../../attachment/attachment_media_type.dart';
import '../../meeting_place_protocol.dart';
import '../../v_card/v_card.dart';
import 'group_member_inauguration_body.dart';

class GroupMemberInauguration {
  factory GroupMemberInauguration.create({
    required String from,
    required List<String> to,
    required GroupMemberInaugurationBody body,
    VCard? vCard,
  }) {
    return GroupMemberInauguration(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: body,
      vCard: vCard,
    );
  }

  factory GroupMemberInauguration.fromPlainTextMessage(
      PlainTextMessage message) {
    VCard? vCard;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      final base64 = message.attachments!.first.data?.base64;
      if (base64 != null) {
        vCard = VCard.fromBase64(base64);
      }
    }
    return GroupMemberInauguration(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: GroupMemberInaugurationBody.fromJson(message.body!),
      vCard: vCard,
      createdTime: message.createdTime,
    );
  }

  GroupMemberInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.vCard,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final GroupMemberInaugurationBody body;
  final VCard? vCard;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.groupMemberInauguration.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: vCard == null
          ? null
          : [
              Attachment(
                id: const Uuid().v4(),
                format: AttachmentFormat.contactCard.value,
                mediaType: AttachmentMediaType.textVcard.value,
                description: 'vCard Info',
                data: AttachmentData(base64: vCard!.toBase64()),
              ),
            ],
    );
  }
}
