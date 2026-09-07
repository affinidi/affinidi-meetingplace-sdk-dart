import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'attachment_format.dart';
import 'attachment_media_type.dart';

/// A DIDComm message [Attachment] carrying a contact card.
class ContactCardAttachment extends Attachment {
  /// Creates a [ContactCardAttachment] from its constituent attachment
  /// fields.
  ContactCardAttachment({
    super.id,
    super.description,
    super.mediaType,
    super.format,
    super.data,
  });

  /// Creates a [ContactCardAttachment] with a generated [id] and the
  /// contact card format and media type pre-filled.
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
