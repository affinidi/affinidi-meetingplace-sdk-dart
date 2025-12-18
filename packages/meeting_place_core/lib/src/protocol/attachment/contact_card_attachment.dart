import 'package:didcomm/didcomm.dart';
import 'attachment_media_type.dart';
import 'attachment_format.dart';
import 'package:uuid/uuid.dart';

class ContactCardAttachment extends Attachment {
  ContactCardAttachment({
    super.id,
    super.description,
    super.mediaType,
    super.format,
    super.data,
  });

  factory ContactCardAttachment.create({
    required AttachmentData data,
    String? description,
  }) {
    return ContactCardAttachment(
      id: const Uuid().v4(),
      format: AttachmentFormat.contactCard.value,
      mediaType: AttachmentMediaType.textContactCard.value,
      description: description,
      data: data,
    );
  }
}
