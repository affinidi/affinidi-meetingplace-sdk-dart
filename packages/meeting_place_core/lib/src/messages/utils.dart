import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import '../protocol/protocol.dart';

ContactCard? getContactCardDataOrEmptyFromAttachments(List<Attachment>? attachments) {
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
