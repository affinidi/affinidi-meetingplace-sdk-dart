import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/attachment.dart';
import '../../contact_card/contact_card.dart';
import '../../meeting_place_protocol.dart';
import '../../contact_card/contact_card_helper.dart';
import 'connection_request_approval_body.dart';

class ConnectionRequestApproval {
  factory ConnectionRequestApproval.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    ContactCard? contactCard,
    List<Attachment>? attachments,
  }) {
    return ConnectionRequestApproval(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: ConnectionRequestApprovalBody(channelDid: channelDid),
      contactCard: contactCard,
      attachments: attachments,
    );
  }

  factory ConnectionRequestApproval.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    final parsed = parseMessageAttachments(message.attachments);

    return ConnectionRequestApproval(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId!,
      body: ConnectionRequestApprovalBody.fromJson(message.body!),
      contactCard: parsed.contactCard,
      attachments: parsed.attachments,
      createdTime: message.createdTime,
    );
  }

  ConnectionRequestApproval({
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
  final ConnectionRequestApprovalBody body;
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
      type: Uri.parse(MeetingPlaceProtocol.connectionRequestApproval.value),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: attachmentsList.isEmpty ? null : attachmentsList,
    );
  }
}
