import '../../../meeting_place_core.dart';

class ContactCardHelper {
  static ContactCardAttachment vCardToAttachment(ContactCard contactCard) {
    return ContactCardAttachment.create(
      data: AttachmentData(base64: contactCard.toBase64(removePadding: true)),
    );
  }
}
