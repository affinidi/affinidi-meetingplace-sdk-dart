import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

/// [ChatReaction] represents an emoji or symbolic reaction
/// to a previously sent chat message.
///
/// It extends [PlainTextMessage] and adds metadata linking the reaction(s)
/// to a target message by ID.
class ChatReaction extends PlainTextMessage {
  /// Creates a new [ChatReaction] instance.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for the reaction message.
  /// - [from]: DID of the user sending the reaction.
  /// - [to]: List of recipient DIDs.
  /// - [reactions]: A list of reactions applied to the message.
  /// - [messageId]: The ID of the message being reacted to.
  ChatReaction({
    required super.id,
    required super.from,
    required super.to,
    required this.reactions,
    required this.messageId,
  }) : super(
          type: Uri.parse(ChatProtocol.chatReaction.value),
          body: {'reactions': reactions, 'messageId': messageId},
        );

  /// Factory constructor to create a new outgoing [ChatReaction].
  ///
  /// Automatically generates a unique [id].
  ///
  /// **Parameters:**
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [reactions]: A list of reactions applied to the message.
  /// - [messageId]: The ID of the message being reacted to.
  ///
  /// **Returns:**
  /// - A new [ChatReaction] instance.
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
      reactions: reactions,
      messageId: messageId,
    );
  }

  /// Factory constructor to parse an incoming [PlainTextMessage]
  /// into a [ChatReaction].
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] containing reaction data.
  ///
  /// **Returns:**
  /// - A reconstructed [ChatReaction] instance.
  factory ChatReaction.fromMessage(PlainTextMessage message) {
    return ChatReaction(
      id: message.id,
      from: message.from,
      to: message.to,
      // ignore: avoid_dynamic_calls
      reactions: message.body?['reactions'].cast<String>() as List<String>,
      messageId: message.body?['messageId'] as String,
    );
  }

  /// The ID of the message that this reaction is applied to.
  final String messageId;

  /// List of reactions (e.g., emojis) applied to the target message.
  final List<String> reactions;
}
