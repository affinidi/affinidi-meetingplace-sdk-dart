import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_delivered_body.dart';

class ChatDelivered {
  factory ChatDelivered.create({
    required String from,
    required List<String> to,
    required List<String> messages,
  }) {
    return ChatDelivered(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatDeliveredBody(messages: messages),
    );
  }

  factory ChatDelivered.fromPlainTextMessage(PlainTextMessage message) {
    return ChatDelivered(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatDeliveredBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatDelivered({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatDeliveredBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatDelivered.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
