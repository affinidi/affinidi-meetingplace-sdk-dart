import 'package:didcomm/didcomm.dart';

import '../../protocol/message/plaintext_message_extension.dart';
import '../../protocol/meeting_place_protocol.dart';
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
    String? messageHash,
  }) async {
    if (message.isOfType(MeetingPlaceProtocol.groupMessage.value)) {
      final decrypted = await _decryptGroupMessage(message, keyRepository);
      return MediatorMessage(
        plainTextMessage: decrypted,
        seqNo: message.body!['seqNo'] as int?,
        fromDid: message.body!['fromDid'] as String?,
        messageHash: messageHash,
      );
    }

    return MediatorMessage(plainTextMessage: message, messageHash: messageHash);
  }

  static Future<PlainTextMessage> _decryptGroupMessage(
    PlainTextMessage message,
    KeyRepository keyRepository,
  ) async {
    final keyPair = await keyRepository.getKeyPair(message.to!.first) ??
        (throw Exception(
            'Key pair not found for DID: ${message.to!.first.topAndTail()}'));

    return GroupMessage.decrypt(message,
        privateKeyBytes: keyPair.privateKeyBytes);
  }
}
