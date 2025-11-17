import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import '../../v_card/v_card.dart';
import '../../v_card/v_card_helper.dart';
import 'connection_request_approval_body.dart';

class ConnectionRequestApproval {
  factory ConnectionRequestApproval.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String channelDid,
    VCard? vCard,
  }) {
    return ConnectionRequestApproval(
      id: const Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: ConnectionRequestApprovalBody(channelDid: channelDid),
      vCard: vCard,
    );
  }

  factory ConnectionRequestApproval.fromPlainTextMessage(
      PlainTextMessage message) {
    VCard? vCard;
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      final base64 = message.attachments!.first.data?.base64;
      if (base64 != null) {
        vCard = VCard.fromBase64(base64);
      }
    }

    return ConnectionRequestApproval(
      id: message.id,
      from: message.from!,
      to: message.to!,
      parentThreadId: message.parentThreadId!,
      body: ConnectionRequestApprovalBody.fromJson(message.body!),
      vCard: vCard,
      createdTime: message.createdTime,
    );
  }

  ConnectionRequestApproval({
    required this.id,
    required this.from,
    required this.to,
    required this.parentThreadId,
    required this.body,
    this.vCard,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final String parentThreadId;
  final ConnectionRequestApprovalBody body;
  final VCard? vCard;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.connectionRequestApproval.value),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      body: body.toJson(),
      createdTime: createdTime,
      attachments:
          vCard == null ? null : [VCardHelper.vCardToAttachment(vCard!)],
    );
  }
}
