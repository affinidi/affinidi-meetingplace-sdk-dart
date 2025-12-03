import 'package:uuid/uuid.dart';

import '../../../meeting_place_chat.dart';

/// DIDComm message sent when requesting credential verification
class ChatRequestCredential {
  /// Creates a ChatRequestCredential message
  static PlainTextMessage create({
    required String from,
    required List<String> to,
    required int seqNo,
    Map<String, dynamic>? credentialMeta,
  }) {
    return PlainTextMessage(
      id: const Uuid().v4(),
      type: Uri.parse(ChatProtocol.chatRequestCredential.value),
      from: from,
      to: to,
      body: {
        'seqNo': seqNo,
        if (credentialMeta != null) 'credentialMeta': credentialMeta,
      },
    );
  }
}
