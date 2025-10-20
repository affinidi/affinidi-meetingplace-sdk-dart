import 'package:json_annotation/json_annotation.dart';

part 'chat_item.g.dart';

/// Defines the type of a chat item stored in the chat repository.
enum ChatItemType {
  /// A standard chat message sent between participants.
  message,

  /// A concierge/system message (e.g., connection requests,
  /// profile updates, joining group chat approvals).
  conciergeMessage,

  /// An event type message sent to the user
  eventMessage,
}

/// Represents the current status of a [ChatItem].
enum ChatItemStatus {
  /// Message is queued locally but not yet sent.
  queued,

  /// Message has been successfully sent.
  sent,

  /// Message has been delivered to the recipient.
  delivered,

  /// Message has been received by the other party.
  received,

  /// An error occurred while sending or processing the message.
  error,

  /// Waiting for user input/decision (common for concierge messages).
  userInput,

  /// Message has been confirmed (e.g., concierge message resolved).
  confirmed, // TODO: separate concierge message status from chat item status
}

/// [ChatItem] is the base class for any item stored in the chat repository.
///
/// It represents both standard chat messages and concierge messages,
/// and contains metadata such as sender, creation date, and status.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatItem {
  /// Creates a new [ChatItem].
  ///
  /// **Parameters:**
  /// - [chatId]: Unique identifier of the chat this item belongs to.
  /// - [messageId]: Unique identifier of the message within the chat.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [isFromMe]: Whether the message was sent by the current user.
  /// - [dateCreated]: The timestamp indicating when the message was created,
  /// in UTC.
  /// - [status]: Current status of the message (e.g. sent, delivered).
  /// - [type]: Type of message ([ChatItemType.message]
  ///  or [ChatItemType.conciergeMessage]).
  ChatItem({
    required this.chatId,
    required this.messageId,
    required this.senderDid,
    required this.isFromMe,
    required this.dateCreated,
    required this.status,
    required this.type,
  });

  /// Unique identifier of the chat this item belongs to.
  final String chatId;

  /// Unique identifier of the message within the chat.
  final String messageId;

  /// DID of the user who sent the message.
  final String senderDid;

  /// Whether the message was sent by the current user (`true`)
  ///  or received (`false`).
  final bool isFromMe;

  /// The timestamp indicating when the message was created, in UTC.
  final DateTime dateCreated;

  /// Type of the chat item: normal message or concierge message.
  final ChatItemType type;

  /// Current status of the message (e.g., sent, delivered). Refer to the
  /// [ChatItemStatus] enum list.
  ChatItemStatus status;

  /// Serializes the [ChatItem] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the chat item.
  Map<String, dynamic> toJson() {
    return _$ChatItemToJson(this);
  }
}
