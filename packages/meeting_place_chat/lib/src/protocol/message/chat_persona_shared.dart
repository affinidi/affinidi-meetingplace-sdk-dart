import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatPersonaShared extends PlainTextMessage {
  ChatPersonaShared({
    required super.id,
    required super.from,
    required super.to,
    required int seqNo,
  }) : super(
          type: Uri.parse(ChatProtocol.chatPersonaShared.value),
          createdTime: DateTime.now().toUtc(),
          body: {'seqNo': seqNo},
        );

  factory ChatPersonaShared.create({
    required String from,
    required List<String> to,
    required int seqNo,
  }) {
    return ChatPersonaShared(
      id: const Uuid().v4(),
      from: from,
      to: to,
      seqNo: seqNo,
    );
  }
}
