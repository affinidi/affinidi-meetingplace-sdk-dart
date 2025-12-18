import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../contact_card/contact_card.dart';
import '../../meeting_place_protocol.dart';
import '../../contact_card/contact_card_helper.dart';
import 'invitation_acceptance_group_body.dart';

class InvitationAcceptanceGroup {
  factory InvitationAcceptanceGroup.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    required String publicKey,
    ContactCard? contactCard,
  }) {
    return InvitationAcceptanceGroup(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: InvitationAcceptanceGroupBody(
        channelDid: channelDid,
        publicKey: publicKey,
      ),
      contactCard: contactCard,
    );
  }

  factory InvitationAcceptanceGroup.fromPlainTextMessage(
      PlainTextMessage message) {
    ContactCard? contactCard;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      final base64 = message.attachments!.first.data?.base64;
      if (base64 != null) {
        contactCard = ContactCard.fromBase64(base64);
      }
    }
    return InvitationAcceptanceGroup(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId!,
      body: InvitationAcceptanceGroupBody.fromJson(message.body!),
      contactCard: contactCard,
      createdTime: message.createdTime,
    );
  }

  InvitationAcceptanceGroup({
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
  final InvitationAcceptanceGroupBody body;
  final ContactCard? contactCard;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.invitationAcceptanceGroup.value),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: contactCard == null
          ? null
          : [ContactCardHelper.vCardToAttachment(contactCard!)],
    );
  }
}
