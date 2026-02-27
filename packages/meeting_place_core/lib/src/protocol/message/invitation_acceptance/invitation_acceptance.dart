import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/attachment.dart';
import '../../protocol.dart';
import '../../contact_card/contact_card_helper.dart';
import 'invitation_acceptance_body.dart';

class InvitationAcceptance {
  factory InvitationAcceptance.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    ContactCard? contactCard,
    List<Attachment>? attachments,
  }) {
    return InvitationAcceptance(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: InvitationAcceptanceBody(channelDid: channelDid),
      contactCard: contactCard,
      attachments: attachments,
    );
  }

  factory InvitationAcceptance.fromPlainTextMessage(PlainTextMessage message) {
    final parsed = parseMessageAttachments(message.attachments);

    return InvitationAcceptance(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId!,
      body: InvitationAcceptanceBody.fromJson(message.body!),
      contactCard: parsed.contactCard,
      attachments: parsed.attachments,
      createdTime: message.createdTime,
    );
  }

  InvitationAcceptance({
    required this.id,
    required this.from,
    required this.to,
    required this.parentThreadId,
    required this.body,
    this.contactCard,
    this.attachments,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final String parentThreadId;
  final InvitationAcceptanceBody body;
  final ContactCard? contactCard;
  final List<Attachment>? attachments;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    final attachmentsList = <Attachment>[];
    if (contactCard != null) {
      attachmentsList.add(ContactCardHelper.vCardToAttachment(contactCard!));
    }
    if (attachments != null) {
      attachmentsList.addAll(attachments!);
    }

    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.invitationAcceptance.value),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: attachmentsList.isEmpty ? null : attachmentsList,
    );
  }
}
