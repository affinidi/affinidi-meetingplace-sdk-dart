import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatDeclinedPersonaSharing extends PlainTextMessage {
  ChatDeclinedPersonaSharing({
    required super.id,
    required super.from,
    required super.to,
  }) : super(
         type: Uri.parse(ChatProtocol.chatDeclinedPersonaSharing.value),
         createdTime: DateTime.now().toUtc(),
       );

  factory ChatDeclinedPersonaSharing.create({
    required String from,
    required List<String> to,
  }) {
    return ChatDeclinedPersonaSharing(
      id: const Uuid().v4(),
      from: from,
      to: to,
    );
  }
}
