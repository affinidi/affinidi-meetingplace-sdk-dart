import 'package:didcomm/didcomm.dart';
import '../attachment/v_card_attachment.dart';
import '../mpx_protocol.dart';
import '../v_card/v_card.dart';
import 'package:uuid/uuid.dart';

class ConnectionSetupGroup extends PlainTextMessage {
  ConnectionSetupGroup({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    required String memberPublicKey,
    VCard? vCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.connectionSetupGroup.value),
          body: {
            'channel_did': permanentChannelDid,
            'public_key': memberPublicKey,
          },
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

  factory ConnectionSetupGroup.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    required String memberPublicKey,
    VCard? vCard,
  }) {
    return ConnectionSetupGroup(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      memberPublicKey: memberPublicKey,
      vCard: vCard,
    );
  }
}
