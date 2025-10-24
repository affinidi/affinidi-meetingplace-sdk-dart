import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

/// [ChatMessage] represents a plain text chat message exchanged
/// between participants in the chat system.
///
/// It extends [PlainTextMessage] by providing structured fields
/// for the message text, sequence number, and attachments.
///
/// A `ChatMessage` can be created locally for sending, or
/// reconstructed from an incoming [PlainTextMessage].
class ChatMessage extends PlainTextMessage {
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
      text: text,
      seqNo: seqNo,
      attachments: attachments,
    );
  }

  /// Creates a [ChatMessage] with the given parameters.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for the message.
  /// - [from]: DID of the sender.
  /// - [to]: List of recipient DIDs.
  /// - [attachments]: List of attachments included with the message.
  /// - [text]: The plain text content of the message.
  /// - [seqNo]: Sequence number for ordering within a conversation.
  ///
  /// Automatically sets:
  /// - [type] to [ChatProtocol.chatMessage].
  /// - [body] with `{'text': text, 'seqNo': seqNo}`.
  /// - [createdTime] to the current UTC time.
  ChatMessage({
    required super.id,
    required super.from,
    required super.to,
    required super.attachments,
    required this.text,
    required this.seqNo,
  }) : super(
          type: Uri.parse(ChatProtocol.chatMessage.value),
          body: {'text': text, 'seqNo': seqNo},
          createdTime: DateTime.now().toUtc(),
        );

  /// The plain text content of the chat message.
  final String text;

  /// Sequence number for ordering messages within a conversation.
  final int seqNo;
}
