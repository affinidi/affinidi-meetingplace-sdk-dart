import 'package:didcomm/didcomm.dart';
import '../../attachment/v_card_attachment.dart';
import '../../meeting_place_protocol.dart';
import '../../v_card/v_card.dart';
import 'package:uuid/uuid.dart';
import 'invitation_acceptance_body.dart';

class InvitationAcceptance extends PlainTextMessage {
  InvitationAcceptance({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    VCard? vCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.invitationAcceptance.value),
          body: InvitationAcceptanceBody(
            channelDid: permanentChannelDid,
          ).toJson(),
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

  factory InvitationAcceptance.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    VCard? vCard,
  }) {
    return InvitationAcceptance(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      vCard: vCard,
    );
  }
}
