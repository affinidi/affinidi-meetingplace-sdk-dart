import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/attachment.dart';
import '../../contact_card/contact_card.dart';
import '../../contact_card/contact_card_helper.dart';
import '../../meeting_place_protocol.dart';
import 'connection_request_approval_body.dart';

/// A connection-request-approval DIDComm message, sent to approve a
/// connection request raised against a published offer.
class ConnectionRequestApproval {
  /// Creates a new [ConnectionRequestApproval] message with a generated
  /// [id].
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

  /// Creates a [ConnectionRequestApproval] from a decoded [PlainTextMessage].
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

  /// Creates a [ConnectionRequestApproval] from its constituent message
  /// fields.
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

  /// The DIDComm message id.
  final String id;

  /// The DID of the sender.
  final String from;

  /// The DIDs of the message recipients.
  final List<String> to;

  /// The id of the thread this message replies to.
  final String parentThreadId;

  /// The message body carrying the approved channel's DID.
  final ConnectionRequestApprovalBody body;

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
