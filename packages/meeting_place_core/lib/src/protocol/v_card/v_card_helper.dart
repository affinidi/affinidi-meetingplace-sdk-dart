import '../../../meeting_place_core.dart';

class VCardHelper {
  static VCardAttachment vCardToAttachment(VCard vCard) {
    return VCardAttachment.create(
      data: AttachmentData(base64: vCard.toBase64(removePadding: true)),
    );
  }
}
