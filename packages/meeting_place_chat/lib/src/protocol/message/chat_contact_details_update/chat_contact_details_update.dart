import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';

class ChatContactDetailsUpdate {
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

  factory ChatContactDetailsUpdate.fromPlainTextMessage(
      PlainTextMessage message) {
    return ChatContactDetailsUpdate(
      id: message.id,
      from: message.from!,
      to: message.to!,
      profileDetails: message.body!,
      createdTime: message.createdTime,
    );
  }

  ChatContactDetailsUpdate({
    required this.id,
    required this.from,
    required this.to,
    required this.profileDetails,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final Map<String, dynamic> profileDetails;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatContactDetailsUpdate.value),
      from: from,
      to: to,
      body: profileDetails,
      createdTime: createdTime,
    );
  }
}
