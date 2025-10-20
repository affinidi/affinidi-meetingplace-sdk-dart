import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

/// [ChatActivity] represents a "user is active" indicator in the chat,
/// similar to typing notifications or activity pings.
///
/// It extends [PlainTextMessage] and includes a timestamp in the `body`
/// indicating when the activity was triggered.
///
/// This message is temporary and is not stored long-term.
class ChatActivity extends PlainTextMessage {
  /// Creates a new [ChatActivity] instance.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for this activity message.
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  ///
  /// Automatically sets:
  /// - [type] to [ChatProtocol.chatActivity].
  /// - [body] with the current UTC timestamp.
  ChatActivity({required super.id, required super.from, required super.to})
      : super(
          type: Uri.parse(ChatProtocol.chatActivity.value),
          body: {'timestamp': DateTime.now().toUtc().toIso8601String()},
        );

  /// Factory constructor to create a new outgoing [ChatActivity].
  ///
  /// Automatically generates a unique [id] and assigns the current UTC
  /// timestamp.
  ///
  /// **Parameters:**
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  ///
  /// **Returns:**
  /// - A new [ChatActivity] instance.
  factory ChatActivity.create({
    required String from,
    required List<String> to,
  }) {
    return ChatActivity(id: const Uuid().v4(), from: from, to: to);
  }
}
