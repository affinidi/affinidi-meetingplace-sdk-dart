import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_reaction_body.dart';

/// [ChatReaction] represents an emoji or symbolic reaction
/// to a previously sent chat message.
///
/// It adds metadata linking the reaction(s) to a target message by ID.
class ChatReaction {
  factory ChatReaction.create({
    required String from,
    required List<String> to,
    required List<String> reactions,
    required String messageId,
  }) {
    return ChatReaction(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatReactionBody(reactions: reactions, messageId: messageId),
    );
  }

  factory ChatReaction.fromPlainTextMessage(PlainTextMessage message) {
    return ChatReaction(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatReactionBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatReaction({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatReactionBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatReaction.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
