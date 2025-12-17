import 'package:didcomm/didcomm.dart';
import '../attachment/contact_card_attachment.dart';
import '../meeting_place_protocol.dart';
import '../contact_card.dart';
import 'package:uuid/uuid.dart';

class ConnectionSetupGroup extends PlainTextMessage {
  ConnectionSetupGroup({
    required super.id,
    required super.from,
    required super.to,
    required super.parentThreadId,
    required String permanentChannelDid,
    required String memberPublicKey,
    ContactCard? contactCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.connectionSetupGroup.value),
          body: {
            'channel_did': permanentChannelDid,
            'public_key': memberPublicKey,
          },
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

  factory ConnectionSetupGroup.create({
    required String from,
    required List<String> to,
    required String parentThreadId,
    required String permanentChannelDid,
    required String memberPublicKey,
    ContactCard? contactCard,
  }) {
    return ConnectionSetupGroup(
      id: Uuid().v4(),
      from: from,
      to: to,
      parentThreadId: parentThreadId,
      permanentChannelDid: permanentChannelDid,
      memberPublicKey: memberPublicKey,
      contactCard: contactCard,
    );
  }
}
