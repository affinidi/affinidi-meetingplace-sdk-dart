import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_effect_body.dart';

/// [ChatEffect] represents a visual or animated effect sent in chat.
///
/// Effects include reactions like confetti, fireworks,
/// or other temporary visual indicators to enhance conversation.
class ChatEffect {
  factory ChatEffect.create({
    required String from,
    required List<String> to,
    required String effect,
  }) {
    return ChatEffect(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatEffectBody(effect: effect),
    );
  }

  factory ChatEffect.fromPlainTextMessage(PlainTextMessage message) {
    return ChatEffect(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatEffectBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatEffect({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatEffectBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatEffect.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
