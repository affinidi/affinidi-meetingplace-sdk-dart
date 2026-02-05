import 'dart:convert';

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

ContactCard? getContactCardDataOrEmptyFromAttachments(
  List<Attachment>? attachments,
) {
  if (attachments == null) {
    return null;
  }

  final base64 = const Base64Codec();
  final card = getAttachmentWithFormat(
    attachments,
    AttachmentFormat.contactCard,
  );

  if (card == null) {
    return null;
  }

  try {
    final normalized = base64Url.decode(base64.normalize(card.data!.base64!));
    final jsonMap = jsonDecode(utf8.decode(normalized)) as Map<String, dynamic>;
    return ContactCard.fromJson(jsonMap);
  } catch (ex) {
    return null;
  }
}

Attachment? getAttachmentWithFormat(
  List<Attachment> attachments,
  AttachmentFormat type,
) {
  return attachments
      .where((element) => element.format! == type.value)
      .firstOrNull;
}
