import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../attachment/v_card_attachment.dart';
import '../../meeting_place_protocol.dart';
import '../../v_card/v_card.dart';

import 'connection_request_approval_body.dart';

class ConnectionRequestApproval extends PlainTextMessage {
  ConnectionRequestApproval({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    VCard? vCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.connectionRequestApproval.value),
          body: ConnectionRequestApprovalBody(channelDid: permanentChannelDid)
              .toJson(),
          createdTime: DateTime.now().toUtc(),
          attachments: vCard is VCard
              ? [
                  VCardAttachment.create(
                    data: AttachmentData(
                      base64: vCard.toBase64(removePadding: true),
                    ),
                  ),
                ]
              : null,
        );

  factory ConnectionRequestApproval.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    VCard? vCard,
  }) {
    return ConnectionRequestApproval(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      vCard: vCard,
    );
  }
}
