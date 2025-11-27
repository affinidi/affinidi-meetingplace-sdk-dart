import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import '../protocol/protocol.dart';

ContactCard? getVCardDataOrEmptyFromAttachments(List<Attachment>? attachments) {
  if (attachments == null) {
    return null;
  }

  final base64 = const Base64Codec();
  final vCard = getAttachmentWithFormat(
    attachments,
    AttachmentFormat.contactCard,
  );

  if (vCard == null) {
    return null;
  }

  try {
    final normalized = base64Url.decode(base64.normalize(vCard.data!.base64!));
    return ContactCard(
      values: jsonDecode(utf8.decode(normalized)) as Map<dynamic, dynamic>,
    );
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
