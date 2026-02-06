import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';

import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../protocol/attachment/attachment_format.dart';
import '../../protocol/message/plaintext_message_extension.dart';
import '../../protocol/meeting_place_protocol.dart';
import '../../protocol/protocol.dart' as protocol;
import '../../repository/repository.dart';
import '../../service/group/group_message.dart';
import '../../utils/string.dart';

class MediatorMessage {
  MediatorMessage({
    required this.plainTextMessage,
    this.messageHash,
    this.seqNo,
    this.fromDid,
  });

  final PlainTextMessage plainTextMessage;
  final String? messageHash;
  final int? seqNo;
  final String? fromDid;

  /// Create a MediatorMessage from a PlainTextMessage
  static Future<MediatorMessage> fromPlainTextMessage(
    PlainTextMessage message, {
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
    String? messageHash,
  }) async {
    if (message.isOfType(MeetingPlaceProtocol.groupMessage.value)) {
      final decrypted = await _decryptGroupMessage(message, keyRepository);
      return MediatorMessage(
        plainTextMessage: decrypted,
        seqNo: message.body!['seq_no'] as int?,
        fromDid: message.body!['from_did'] as String?,
        messageHash: messageHash,
      );
    }

    if (message.type == ProblemReportMessage.messageType) {
      logger.warning(
        'Received problem report message: ${jsonEncode(message.body)}',
        name: 'MediatorMessage.fromPlainTextMessage',
      );
    }

    return MediatorMessage(plainTextMessage: message, messageHash: messageHash);
  }

  int? get messageSequenceNumber {
    if (seqNo != null) {
      return seqNo;
    }

    final seqNoFromBody = plainTextMessage.body?['seq_no'] as int?;
    if (seqNoFromBody != null) {
      return seqNoFromBody;
    }

    return _getSeqNoFromAttachment();
  }

  int? _getSeqNoFromAttachment() {
    final attachment = plainTextMessage.attachments?.firstWhereOrNull(
      (attachment) => attachment.format == AttachmentFormat.seqNo.value,
    );

    if (attachment?.data?.json == null) return null;

    final json = jsonDecode(attachment!.data!.json!);
    return json['seq_no'] as int?;
  }

  static Future<PlainTextMessage> _decryptGroupMessage(
    PlainTextMessage message,
    KeyRepository keyRepository,
  ) async {
    final keyPair =
        await keyRepository.getKeyPair(message.to!.first) ??
        (throw Exception(
          'Key pair not found for DID: ${message.to!.first.topAndTail()}',
        ));

    final groupMessage = protocol.GroupMessage.fromPlainTextMessage(message);
    return GroupMessage.decrypt(
      groupMessage,
      privateKeyBytes: keyPair.privateKeyBytes,
    );
  }
}
