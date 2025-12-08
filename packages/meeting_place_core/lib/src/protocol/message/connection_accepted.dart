import 'package:didcomm/didcomm.dart';
import '../attachment/contact_card_attachment.dart';
import '../meeting_place_protocol.dart';
import '../../entity/contact_card.dart';
import 'package:uuid/uuid.dart';

class ConnectionAccepted extends PlainTextMessage {
  ConnectionAccepted({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    ContactCard? contactCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.connectionAccepted.value),
          body: {'channel_did': permanentChannelDid},
          createdTime: DateTime.now().toUtc(),
          attachments: contactCard != null
              ? [
                  ContactCardAttachment.create(
                    data: AttachmentData(
                      base64: contactCard.toBase64(removePadding: true),
                    ),
                  ),
                ]
              : null,
        );

  factory ConnectionAccepted.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    ContactCard? contactCard,
  }) {
    return ConnectionAccepted(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      contactCard: contactCard,
    );
  }
}
