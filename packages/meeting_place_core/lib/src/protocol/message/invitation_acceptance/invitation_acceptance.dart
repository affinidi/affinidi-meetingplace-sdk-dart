import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/attachment.dart';
import '../../contact_card/contact_card_helper.dart';
import '../../protocol.dart';
import 'invitation_acceptance_body.dart';

/// An invitation-acceptance DIDComm message, sent to accept an invitation to
/// connect.
class InvitationAcceptance {
  /// Creates a new [InvitationAcceptance] message with a generated [id].
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

  /// Creates an [InvitationAcceptance] from a decoded [PlainTextMessage].
  factory InvitationAcceptance.fromPlainTextMessage(PlainTextMessage message) {
    final parsed = parseMessageAttachments(message.attachments);

    return InvitationAcceptance(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId,
      body: InvitationAcceptanceBody.fromJson(message.body!),
      contactCard: parsed.contactCard,
      attachments: parsed.attachments,
      createdTime: message.createdTime,
    );
  }

  /// Creates an [InvitationAcceptance] from its constituent message fields.
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

  /// The DIDComm message id.
  final String id;

  /// The DID of the sender.
  final String from;

  /// The DIDs of the message recipients.
  final List<String> to;

  /// The id of the thread this message replies to, if any.
  final String? parentThreadId;

  /// The message body carrying the accepted channel's DID.
  final InvitationAcceptanceBody body;

  /// The sender's contact card, if shared.
  final ContactCard? contactCard;

  /// Attachments carried alongside this message.
  final List<Attachment>? attachments;

  /// When this message was created.
  final DateTime createdTime;

  /// Converts this message to a [PlainTextMessage] for transport.
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
