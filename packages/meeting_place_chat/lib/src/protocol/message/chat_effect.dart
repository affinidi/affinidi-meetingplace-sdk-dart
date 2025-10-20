import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

/// [ChatEffect] represents a visual or animated effect sent in chat.
///
/// Effects include reactions like confetti, fireworks,
/// or other temporary visual indicators to enhance conversation.
///
/// It extends [PlainTextMessage] and embeds the effect in the `body`.
class ChatEffect extends PlainTextMessage {
  /// Creates a new [ChatEffect] message.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for this chat effect message.
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [effect]: The name or identifier of the effect to trigger.
  /// - [vCard]: Optional vCard metadata of the sender.
  ChatEffect({
    required super.id,
    required super.from,
    required super.to,
    required String effect, // TODO: convert to enum?
    VCard? vCard,
  }) : super(
          type: Uri.parse(ChatProtocol.chatEffect.value),
          body: {'effect': effect},
        );

  /// Factory constructor to conveniently create a new outgoing [ChatEffect].
  ///
  /// Automatically generates a unique [id] and populates
  /// the `body` field with the provided effect.
  ///
  /// **Parameters:**
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [effect]: The effect name or identifier.
  ///
  /// **Returns:**
  /// - A new [ChatEffect] instance.
  factory ChatEffect.create({
    required String from,
    required List<String> to,
    required String effect,
  }) {
    return ChatEffect(
      id: const Uuid().v4(),
      from: from,
      to: to,
      effect: effect,
    );
  }
}
