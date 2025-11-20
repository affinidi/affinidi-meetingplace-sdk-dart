import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'attachment_format.dart';
import 'attachment_media_type.dart';

class VCardAttachment extends Attachment {
  VCardAttachment({
    super.id,
    super.description,
    super.mediaType,
    super.format,
    super.data,
  });

  factory VCardAttachment.create({
    required AttachmentData data,
    String? description,
  }) {
    return VCardAttachment(
      id: const Uuid().v4(),
      format: AttachmentFormat.contactCard.value,
      mediaType: AttachmentMediaType.textVcard.value,
      description: description,
      data: data,
    );
  }
}
