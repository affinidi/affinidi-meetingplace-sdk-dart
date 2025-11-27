import 'package:didcomm/didcomm.dart';
import '../attachment/v_card_attachment.dart';
import '../meeting_place_protocol.dart';
import '../v_card/contact_card.dart';
import 'package:uuid/uuid.dart';

class ConnectionSetup extends PlainTextMessage {
  ConnectionSetup({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    ContactCard? vCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.connectionSetup.value),
          body: {'channel_did': permanentChannelDid},
          createdTime: DateTime.now().toUtc(),
          attachments: vCard is ContactCard
              ? [
                  VCardAttachment.create(
                    data: AttachmentData(
                      base64: vCard.toBase64(removePadding: true),
                    ),
                  ),
                ]
              : null,
        );

  factory ConnectionSetup.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    ContactCard? vCard,
  }) {
    return ConnectionSetup(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      vCard: vCard,
    );
  }
}
