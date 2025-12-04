import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatPersonaShared extends PlainTextMessage {
  ChatPersonaShared({
    required super.id,
    required super.from,
    required super.to,
  }) : super(
          type: Uri.parse(ChatProtocol.chatPersonaShared.value),
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatPersonaShared.create({
    required String from,
    required List<String> to,
  }) {
    return ChatPersonaShared(
      id: const Uuid().v4(),
      from: from,
      to: to,
    );
  }
}
