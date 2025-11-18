import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_presence_body.dart';

class ChatPresence extends PlainTextMessage {
  ChatPresence({required super.id, required super.from, required super.to})
      : super(
          type: Uri.parse(ChatProtocol.chatPresence.value),
          body: ChatPresenceBody(timestamp: DateTime.now().toUtc()).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatPresence.create({
    required String from,
    required List<String> to,
  }) {
    return ChatPresence(id: const Uuid().v4(), from: from, to: to);
  }
}
