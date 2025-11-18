import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_presence_body.dart';

class ChatPresence {
  factory ChatPresence.create({
    required String from,
    required List<String> to,
  }) {
    final now = DateTime.now().toUtc();
    return ChatPresence(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatPresenceBody(timestamp: now),
      createdTime: now,
    );
  }

  factory ChatPresence.fromPlainTextMessage(PlainTextMessage message) {
    return ChatPresence(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatPresenceBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatPresence({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatPresenceBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatPresence.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
