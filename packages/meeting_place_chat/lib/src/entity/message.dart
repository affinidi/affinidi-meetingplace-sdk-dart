import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol/message/chat_message/chat_message.dart';
import 'chat_attachment.dart';
import 'chat_attachment_conversion.dart';
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
/// - From a received `PlainTextMessage`
/// - From a sent `ChatMessage`
/// - From any `PlainTextMessage` using the generic factory
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
  /// from a received `ChatMessage`.
  ///
  /// It sets the status to [ChatItemStatus.received] and marks
  /// the message as not created by the current user (`createdByMe = false`).
  ///
  /// **Parameters:**
  /// - [message]: The received `ChatMessage`.
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
      attachments: message.attachments
          .map((a) => a.toChatAttachment())
          .toList(),
      status: ChatItemStatus.received,
      createdByMe: false,
    );
  }

  /// Factory constructor to create a [Message] from a locally sent
  ///  chat message.
  ///
  /// This sets the status to [ChatItemStatus.queued] until delivery
  ///  is confirmed
  /// and marks the message as created by the current user
  ///  (`createdByMe = true`).
  ///
  /// **Parameters:**
  /// - [message]: The sent `ChatMessage`.
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
      attachments: message.attachments
          .map((a) => a.toChatAttachment())
          .toList(),
      status: ChatItemStatus.queued,
      createdByMe: true,
    );
  }

  /// Generic factory constructor to create a [Message]
  ///  from any `ChatMessage`.
  ///
  /// Handles both direct and group messages, mapping text and attachments.
  /// **Parameters:**
  /// - [message]: The `ChatMessage` to parse.
  /// - [chatId]: The chat ID derived from DIDs.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [createdByMe]: Whether the message was created by the current user.
  /// - [status]: The current status of the message.
  /// - [attachments]: Optional list of [ChatAttachment]s.
  ///
  /// **Returns:**
  /// - A new [Message] instance.
  factory Message.fromPlaintextMessage(
    ChatMessage message, {
    required String chatId,
    required String senderDid,
    required bool createdByMe,
    required ChatItemStatus status,
    List<ChatAttachment>? attachments,
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

  factory Message.fromRoomEventSentByMe({
    required MatrixRoomEvent event,
    required String chatId,
    required String senderDid,
  }) {
    return Message(
      chatId: chatId,
      messageId: event.id,
      senderDid: senderDid,
      value: event.content['body'] as String? ?? '',
      isFromMe: true,
      dateCreated: event.timestamp,
      // Set status to sent since this is created for messages sent by me.
      // The status will be updated to delivered/failed based on the delivery
      // outcome.
      status: ChatItemStatus.sent,
      // TODO: How to add attachments?
      attachments: [],
    );
  }

  factory Message.fromRoomEventReceivedByMe({
    required MatrixRoomEvent event,
    required String chatId,
    required String senderDid,
  }) {
    return Message(
      chatId: chatId,
      messageId: event.id,
      senderDid: senderDid,
      value: event.content['body'] as String? ?? '',
      isFromMe: false,
      dateCreated: event.timestamp,
      status: ChatItemStatus.received,
      attachments: [],
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
  /// - [attachments]: Optional list of [ChatAttachment]s included with the
  /// message (default: empty list).
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
  final List<ChatAttachment> attachments;

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
