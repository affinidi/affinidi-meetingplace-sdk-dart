import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_activity_body.dart';

/// [ChatActivity] represents a "user is active" indicator in the chat,
/// similar to typing notifications or activity pings.
///
/// It includes a timestamp in the body indicating when the activity was triggered.
///
/// This message is temporary and is not stored long-term.
class ChatActivity {
  factory ChatActivity.create({
    required String from,
    required List<String> to,
  }) {
    final now = DateTime.now().toUtc();
    return ChatActivity(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatActivityBody(timestamp: now),
      createdTime: now,
    );
  }

  factory ChatActivity.fromPlainTextMessage(PlainTextMessage message) {
    return ChatActivity(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatActivityBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatActivity({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatActivityBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatActivity.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
