import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../utils/base64.dart';

class ForwardMessageBuilder {
  static ForwardMessage build(
    EncryptedMessage encryptedMessage, {
    required DidDocument senderDidDocument,
    required MediatorClient mediatorClient,
    required String next,
    int? forwardExpiryInSeconds,
    bool ephemeral = false,
  }) {
    final forwardMessage = ForwardMessage(
      id: const Uuid().v4(),
      from: senderDidDocument.id,
      to: [mediatorClient.mediatorDidDocument.id],
      next: next,
      expiresTime: _getExpiresTime(forwardExpiryInSeconds),
      attachments: [_buildAttachment(encryptedMessage)],
    );

    forwardMessage['ephemeral'] = ephemeral;
    return forwardMessage;
  }

  static DateTime? _getExpiresTime(int? forwardExpiryInSeconds) {
    if (forwardExpiryInSeconds == null) return null;
    return DateTime.now().toUtc().add(
          Duration(seconds: forwardExpiryInSeconds),
        );
  }

  static Attachment _buildAttachment(EncryptedMessage encryptedMessage) {
    return Attachment(
      mediaType: 'application/json',
      data: AttachmentData(
        base64: removePaddingFromBase64(
          base64UrlEncode(utf8.encode(jsonEncode(encryptedMessage))),
        ),
      ),
    );
  }
}
