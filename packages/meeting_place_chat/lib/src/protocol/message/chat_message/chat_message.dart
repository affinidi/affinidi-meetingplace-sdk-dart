import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_message_body.dart';

/// [ChatMessage] represents a plain text chat message exchanged
/// between participants in the chat system.
///
/// It provides structured fields for the message text, sequence number,
/// and attachments.
///
/// A `ChatMessage` can be created locally for sending, or
/// reconstructed from an incoming [PlainTextMessage].
class ChatMessage {
  /// Factory constructor to create a new outgoing [ChatMessage].
  ///
  /// **Parameters:**
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [text]: The plain text content of the message.
  /// - [seqNo]: Sequence number for ordering within a conversation.
  /// - [attachments]: Optional list of [Attachment]s included with the message
  /// (default: empty list).
  ///
  /// **Returns:**
  /// - A new [ChatMessage] instance ready to be sent.
  factory ChatMessage.create({
    required String from,
    required List<String> to,
    required String text,
    required int seqNo,
    List<Attachment> attachments = const [],
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatMessageBody(
        text: text,
        seqNo: seqNo,
        timestamp: DateTime.now().toUtc(),
      ),
      attachments: attachments,
    );
  }

  factory ChatMessage.fromPlainTextMessage(PlainTextMessage message) {
    return ChatMessage(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatMessageBody.fromJson(message.body!),
      attachments: message.attachments ?? [],
      createdTime: message.createdTime,
    );
  }

  /// Creates a [ChatMessage] with the given parameters.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for the message.
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [body]: The typed message body containing text and seqNo.
  /// - [attachments]: List of attachments included with the message.
  /// - [createdTime]: Optional creation timestamp.
  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.attachments = const [],
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatMessageBody body;
  final List<Attachment> attachments;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: from,
      to: to,
      body: body.toJson(),
      attachments: attachments.isEmpty ? null : attachments,
      createdTime: createdTime,
    );
  }
}
