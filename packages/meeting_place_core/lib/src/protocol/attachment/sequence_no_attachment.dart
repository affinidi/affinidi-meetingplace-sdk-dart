import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'attachment_media_type.dart';
import 'attachment_format.dart';
import 'package:uuid/uuid.dart';

class SequenceNoAttachment extends Attachment {
  SequenceNoAttachment({
    super.id,
    super.description,
    super.mediaType,
    super.format,
    super.data,
  });

  factory SequenceNoAttachment.create({required int seqNo}) {
    return SequenceNoAttachment(
      id: const Uuid().v4(),
      format: AttachmentFormat.seqNo.value,
      mediaType: AttachmentMediaType.json.value,
      data: AttachmentData.fromJson({
        'json': jsonEncode({'seq_no': seqNo}),
      }),
    );
  }
}
