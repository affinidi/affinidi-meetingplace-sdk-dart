import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatContactDetailsUpdate extends PlainTextMessage {
  ChatContactDetailsUpdate({
    required super.id,
    required super.from,
    required super.to,
    required Map<String, dynamic> profileDetails,
  }) : super(
          type: Uri.parse(ChatProtocol.chatContactDetailsUpdate.value),
          body: profileDetails,
        );

  factory ChatContactDetailsUpdate.create({
    required String from,
    required List<String> to,
    required Map<String, dynamic> profileDetails,
  }) {
    return ChatContactDetailsUpdate(
      id: const Uuid().v4(),
      from: from,
      to: to,
      profileDetails: profileDetails,
    );
  }
}
