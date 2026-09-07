import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../contact_card/contact_card.dart';
import '../../contact_card/contact_card_helper.dart';
import '../../meeting_place_protocol.dart';
import 'invitation_acceptance_group_body.dart';

/// An invitation-acceptance-group DIDComm message, sent to accept an
/// invitation to join a group.
class InvitationAcceptanceGroup {
  /// Creates a new [InvitationAcceptanceGroup] message with a generated
  /// [id].
  factory InvitationAcceptanceGroup.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    ContactCard? contactCard,
  }) {
    return InvitationAcceptanceGroup(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: InvitationAcceptanceGroupBody(channelDid: channelDid),
      contactCard: contactCard,
    );
  }

  /// Creates an [InvitationAcceptanceGroup] from a decoded
  /// [PlainTextMessage].
  factory InvitationAcceptanceGroup.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
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

  /// Creates an [InvitationAcceptanceGroup] from its constituent message
  /// fields.
  InvitationAcceptanceGroup({
    required this.id,
    required this.from,
    required this.to,
    required this.parentThreadId,
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

  /// The id of the thread this message replies to.
  final String parentThreadId;

  /// The message body carrying the accepted group channel's DID.
  final InvitationAcceptanceGroupBody body;

  /// The sender's contact card, if shared.
  final ContactCard? contactCard;

  /// When this message was created.
  final DateTime createdTime;

  /// Converts this message to a [PlainTextMessage] for transport.
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
