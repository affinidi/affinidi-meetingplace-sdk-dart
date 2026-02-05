import 'package:didcomm/didcomm.dart';
import 'package:json_annotation/json_annotation.dart';

import '../protocol/message/chat_message/chat_message.dart';
import '../protocol/protocol.dart' as protocol;
import 'chat_item.dart';

part 'message.g.dart';

/// [Message] represents a standard chat message exchanged between participants.
///
/// It extends [ChatItem] and adds support for:
/// - Plain text message ([value])
/// - File or media attachments ([attachments])
/// - User reactions ([reactions])
///
/// A [Message] can be created in three main ways:
/// - From a **received** [PlainTextMessage]
/// - From a **sent** `protocol.ChatMessage`
/// - From any [PlainTextMessage] using the generic factory
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Message extends ChatItem {
  /// Factory constructor to create a [Message] from JSON.
  ///
  /// **Parameters:**
  /// - [json]: A `Map<String, dynamic>` containing serialized [Message] data.
  ///
  /// **Returns:**
  /// - A new [Message] instance.
  factory Message.fromJson(Map<String, dynamic> json) {
    return _$MessageFromJson(json);
  }

  /// Factory constructor to create a [Message]
  /// from a received [PlainTextMessage].
  ///
  /// It sets the status to [ChatItemStatus.received] and marks
  /// the message as not created by the current user (`createdByMe = false`).
  ///
  /// **Parameters:**
  /// - [message]: The received [PlainTextMessage].
  ///
  /// **Returns:**
  /// - A new [Message] instance representing the received message.
  factory Message.fromReceivedMessage({
    required ChatMessage message,
    required String chatId,
  }) {
    return Message.fromPlaintextMessage(
      message,
      chatId: chatId,
      senderDid: message.from,
      attachments: message.attachments,
      status: ChatItemStatus.received,
      createdByMe: false,
    );
  }

  /// Factory constructor to create a [Message] from a locally sent
  ///  chat message.
  ///
  /// This sets the status to [ChatItemStatus.sent] for optimistic UI display
  /// and marks the message as created by the current user
  ///  (`createdByMe = true`).
  ///
  /// **Parameters:**
  /// - [message]: The sent [protocol.ChatMessage].
  ///
  /// **Returns:**
  /// - A new [Message] instance representing the sent message.
  factory Message.fromSentMessage({
    required ChatMessage message,
    required String chatId,
  }) {
    return Message.fromPlaintextMessage(
      chatId: chatId,
      message,
      senderDid: message.from,
      attachments: message.attachments,
      status: ChatItemStatus.sent,
      createdByMe: true,
    );
  }

  /// Generic factory constructor to create a [Message]
  ///  from any [PlainTextMessage].
  ///
  /// Handles both direct and group messages, mapping text and attachments.
  ///
  /// **Parameters:**
  /// - [message]: The [PlainTextMessage] to parse.
  /// - [chatId]: The chat ID derived from DIDs.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [createdByMe]: Whether the message was created by the current user.
  /// - [status]: The current status of the message.
  /// - [attachments]: Optional list of [Attachment]s.
  ///
  /// **Returns:**
  /// - A new [Message] instance.
  factory Message.fromPlaintextMessage(
    ChatMessage message, {
    required String chatId,
    required String senderDid,
    required bool createdByMe,
    required ChatItemStatus status,
    List<Attachment>? attachments,
  }) {
    return Message(
      chatId: chatId,
      messageId: message.id,
      senderDid: senderDid,
      value: message.body.text,
      isFromMe: createdByMe,
      dateCreated: message.body.timestamp,
      status: status,
      attachments: attachments ?? [],
    );
  }

  /// Creates a new [Message].
  ///
  /// **Parameters:**
  /// - [chatId]: Unique identifier of the chat this message belongs to.
  /// - [messageId]: Unique identifier of the message.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [isFromMe]: Whether the message was sent by the current user.
  /// - [dateCreated]: The timestamp indicating when the message was created,
  /// in UTC.
  /// - [status]: Current status of the message.
  /// - [type]: Defaults to [ChatItemType.message].
  /// - [value]: The plain text content of the message.
  /// - [attachments]: Optional list of [Attachment]s included with the message
  /// (default: empty list).
  /// - [reactions]: Optional list of reactions applied to the message
  /// (default: empty list).
  Message({
    required super.chatId,
    required super.messageId,
    required super.senderDid,
    required super.isFromMe,
    required super.dateCreated,
    required super.status,
    super.type = ChatItemType.message,
    required this.value,
    this.attachments = const [],
    List<String> reactions = const [],
  }) : reactions = [...reactions];

  /// The plain text content of the message.
  final String value;

  /// Attachments included with the message (e.g., images, files).
  final List<Attachment> attachments;

  /// List of reactions applied to this message.
  List<String> reactions;

  /// Serializes this [Message] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the message.
  @override
  Map<String, dynamic> toJson() {
    return _$MessageToJson(this);
  }
}
