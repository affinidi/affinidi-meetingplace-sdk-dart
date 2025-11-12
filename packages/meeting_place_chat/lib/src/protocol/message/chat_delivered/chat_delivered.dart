import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_delivered_body.dart';

class ChatDelivered extends PlainTextMessage {
  ChatDelivered({
    required super.id,
    required super.from,
    required super.to,
    required List<String> messages,
  }) : super(
          type: Uri.parse(ChatProtocol.chatDelivered.value),
          body: ChatDeliveredBody(messages: messages).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatDelivered.create({
    required String from,
    required List<String> to,
    required List<String> messages,
  }) {
    return ChatDelivered(
      id: const Uuid().v4(),
      from: from,
      to: to,
      messages: messages,
    );
  }
}
