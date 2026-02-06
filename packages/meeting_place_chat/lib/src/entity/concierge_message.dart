import 'package:json_annotation/json_annotation.dart';
import 'chat_item.dart';

part 'concierge_message.g.dart';

/// Defines the type of concierge message sent in the chat system.
///
/// Concierge messages are **system-level prompts** that often
/// require user confirmation or administrative approval.
enum ConciergeMessageType {
  /// Requests permission from the user to update their profile.
  permissionToUpdateProfile,

  /// Requests permission to join a group chat.
  permissionToJoinGroup,

  /// Requests permission to verify a relationship.
  permissionToVerifyRelationship,

  /// Requests permission to share R Card.
  permissionToShareRCard,
}

/// Represents the approval state of a concierge request.
///
/// These statuses typically apply to **group join requests**
/// or other concierge approval flows.
enum ConciergeStatus {
  /// The request is still awaiting a decision.
  pending,

  /// The request has been approved.
  approved,
}

/// [ConciergeMessage] is a special type of [ChatItem] used to represent
/// system or administrative messages that require user interaction.
///
/// Examples include:
/// - Requests for permission to update a profile.
/// - Requests to join a group.
/// - Approval/confirmation flows.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConciergeMessage extends ChatItem {
  /// Factory constructor to create a [ConciergeMessage] from JSON.
  ///
  /// **Parameters:**
  /// - [json]: The JSON map containing serialized [ConciergeMessage] data.
  ///
  /// **Returns:**
  /// - A new [ConciergeMessage] instance.
  factory ConciergeMessage.fromJson(Map<String, dynamic> json) {
    return _$ConciergeMessageFromJson(json);
  }

  /// Creates a new [ConciergeMessage].
  ///
  /// **Parameters:**
  /// - [chatId]: Unique identifier of the chat this message belongs to.
  /// - [messageId]: Unique identifier of the message within the chat.
  /// - [senderDid]: DID of the user who sent the message.
  /// - [isFromMe]: Whether the message was sent by the current user.
  /// - [dateCreated]: The timestamp indicating when the message was created,
  /// in UTC.
  /// - [status]: Current status of the message.
  /// - [data]: Additional structured metadata required for the concierge
  /// request.
  /// - [conciergeType]: The [ConciergeMessageType] of this message.
  /// - [type]: Always set to [ChatItemType.conciergeMessage].
  ConciergeMessage({
    required super.chatId,
    required super.messageId,
    required super.senderDid,
    required super.isFromMe,
    required super.dateCreated,
    required super.status,
    required this.data,
    required this.conciergeType,
    super.type = ChatItemType.conciergeMessage,
  });

  /// Structured metadata payload for the concierge request.
  final Map<String, dynamic> data;

  /// Type of concierge message
  final ConciergeMessageType conciergeType;

  /// Serializes the [ConciergeMessage] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the message.
  @override
  Map<String, dynamic> toJson() {
    return _$ConciergeMessageToJson(this);
  }
}
