import 'package:json_annotation/json_annotation.dart';

import '../transport/didcomm/protocol/chat_message/chat_message.dart';
import 'chat_attachment.dart';
import 'chat_item.dart';
import 'message_reaction.dart';

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
      transportId: message.id,
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
    List<MessageReaction> reactions = const [],
    this.editedAt,
    this.transportId,
    this.isDeleted = false,
    this.isDeletedLocally = false,
  }) : reactions = [...reactions];

  /// The plain text content of the message. Mutated in place when the
  /// sender edits the message via Matrix's `m.replace` relation.
  String value;

  /// Timestamp of the most recent edit, or `null` if the message has never
  /// been edited. Set from the edit event's server timestamp on incoming
  /// edits, and from the local clock on outgoing optimistic updates.
  DateTime? editedAt;

  /// Identifier assigned by the underlying transport (e.g. the Matrix
  /// `event_id`) once the message has been accepted by the server.
  ///
  /// `null` for messages that have not yet been delivered (queued or failed).
  /// Required as the relation target when sending edits, reactions, or
  /// redactions — those rely on the transport-assigned id, not the local
  /// [messageId], which may have been generated optimistically before send.
  String? transportId;

  /// Attachments included with the message (e.g., images, files). Mutated
  /// in place when the message is tombstoned via [clearContent].
  List<ChatAttachment> attachments;

  /// List of reactions applied to this message. Each entry records both the
  /// emoji and the DID of the participant who applied it, so the same emoji
  /// from different participants is counted separately and a participant can
  /// only toggle their own reaction.
  List<MessageReaction> reactions;

  /// Whether the message has been deleted for all participants via a
  /// transport-level redaction. Set by the original sender's
  /// `BaseChatSDK.deleteMessage` call, or on receipt of a matching
  /// `m.room.redaction` event. [value] is preserved so consumers can still
  /// render a tombstone placeholder.
  bool isDeleted;

  /// Whether the message has been hidden for the local user only via
  /// `deleteMessage(localOnly: true)`. Never broadcast; never set by
  /// incoming events.
  bool isDeletedLocally;

  /// Wipes the user-visible content of the message in place, leaving only
  /// the identity / metadata fields (id, sender, timestamps, transport id,
  /// tombstone flags). Called by `deleteMessage` and on incoming
  /// `m.room.redaction` so the chat repository never holds the original
  /// text or attachment references of a deleted message — defending against
  /// backup or forensic recovery of "deleted" content.
  void clearContent() {
    value = '';
    attachments = [];
    reactions = [];
    editedAt = null;
  }

  /// Serializes this [Message] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the message.
  @override
  Map<String, dynamic> toJson() {
    return _$MessageToJson(this);
  }
}
