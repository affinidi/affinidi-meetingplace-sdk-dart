import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatPresence extends PlainTextMessage {
  ChatPresence({required super.id, required super.from, required super.to})
      : super(
          type: Uri.parse(ChatProtocol.chatPresence.value),
          body: {
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatPresence.create({
    required String from,
    required List<String> to,
  }) {
    return ChatPresence(id: const Uuid().v4(), from: from, to: to);
  }
}
