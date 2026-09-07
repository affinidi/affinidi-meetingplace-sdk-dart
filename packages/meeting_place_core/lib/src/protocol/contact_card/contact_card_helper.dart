import '../../../meeting_place_core.dart';

/// Helper methods for converting between [ContactCard] and its DIDComm
/// attachment representation.
class ContactCardHelper {
  /// Wraps [contactCard] in a [ContactCardAttachment], base64-encoding it
  /// as the attachment data.
  static ContactCardAttachment vCardToAttachment(ContactCard contactCard) {
    return ContactCardAttachment.create(
      data: AttachmentData(base64: contactCard.toBase64(removePadding: true)),
    );
  }
}
