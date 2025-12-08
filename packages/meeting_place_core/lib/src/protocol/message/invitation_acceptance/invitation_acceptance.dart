import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../protocol.dart';
import '../../v_card/v_card_helper.dart';
import 'invitation_acceptance_body.dart';

class InvitationAcceptance {
  factory InvitationAcceptance.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    ContactCard? contactCard,
  }) {
    return InvitationAcceptance(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: InvitationAcceptanceBody(channelDid: channelDid),
      contactCard: contactCard,
    );
  }

  factory InvitationAcceptance.fromPlainTextMessage(PlainTextMessage message) {
    ContactCard? contactCard;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      final base64 = message.attachments!.first.data?.base64;
      if (base64 != null) {
        contactCard = ContactCard.fromBase64(base64);
      }
    }
    return InvitationAcceptance(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId!,
      body: InvitationAcceptanceBody.fromJson(message.body!),
      contactCard: contactCard,
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
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final String parentThreadId;
  final InvitationAcceptanceBody body;
  final ContactCard? contactCard;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.invitationAcceptance.value),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: contactCard == null
          ? null
          : [VCardHelper.vCardToAttachment(contactCard!)],
    );
  }
}
