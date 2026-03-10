import 'package:didcomm/didcomm.dart';

import '../protocol/protocol.dart';

class ParsedAttachments {
  ParsedAttachments({this.contactCard, List<Attachment>? attachments})
    : attachments = attachments?.isNotEmpty == true ? attachments : null;

  final ContactCard? contactCard;
  final List<Attachment>? attachments;
}

ParsedAttachments parseMessageAttachments(
  List<Attachment>? messageAttachments,
) {
  if (messageAttachments == null || messageAttachments.isEmpty) {
    return ParsedAttachments();
  }

  ContactCard? contactCard;
  final otherAttachments = <Attachment>[];

  for (final attachment in messageAttachments) {
    if (attachment.format == AttachmentFormat.contactCard.value) {
      final base64 = attachment.data?.base64;
      if (base64 != null) {
        contactCard = ContactCard.fromBase64(base64);
      }
    } else {
      otherAttachments.add(attachment);
    }
  }

  return ParsedAttachments(
    contactCard: contactCard,
    attachments: otherAttachments,
  );
}
