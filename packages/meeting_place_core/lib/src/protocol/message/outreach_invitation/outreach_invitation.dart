import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'outreach_invitation_body.dart';

class OutreachInvitation {
  factory OutreachInvitation.fromPlainTextMessage(PlainTextMessage message) {
    return OutreachInvitation(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: OutreachInvitationBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  factory OutreachInvitation.create({
    required String from,
    required List<String> to,
    required OutreachInvitationBody body,
  }) {
    return OutreachInvitation(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: body,
    );
  }

  OutreachInvitation({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final OutreachInvitationBody body;
  final DateTime createdTime;

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
