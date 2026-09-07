import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'outreach_invitation_body.dart';

/// An outreach-invitation DIDComm message, sent to invite a prospective
/// contact to connect.
class OutreachInvitation {
  /// Creates an [OutreachInvitation] from a decoded [PlainTextMessage].
  factory OutreachInvitation.fromPlainTextMessage(PlainTextMessage message) {
    return OutreachInvitation(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: OutreachInvitationBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  /// Creates a new [OutreachInvitation] message with a generated [id].
  factory OutreachInvitation.create({
    required String from,
    required List<String> to,
    required String mnemonic,
    required String message,
  }) {
    return OutreachInvitation(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: OutreachInvitationBody(mnemonic: mnemonic, message: message),
    );
  }

  /// Creates an [OutreachInvitation] from its constituent message fields.
  OutreachInvitation({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  /// The DIDComm message id.
  final String id;

  /// The DID of the sender.
  final String from;

  /// The DIDs of the message recipients.
  final List<String> to;

  /// The message body carrying the invitation's mnemonic and message text.
  final OutreachInvitationBody body;

  /// When this message was created.
  final DateTime createdTime;

  /// Converts this message to a [PlainTextMessage] for transport.
  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.outreachInvitation.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
