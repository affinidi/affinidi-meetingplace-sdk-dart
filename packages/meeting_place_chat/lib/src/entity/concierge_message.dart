import 'package:json_annotation/json_annotation.dart';
import 'chat_item.dart';

part 'concierge_message.g.dart';

/// Defines the type of a concierge message.
///
/// Concierge messages are system-level prompts that often require user
/// confirmation or administrative approval.
///
/// Built-in types are exposed as named constants. Custom application-specific
/// types can be created via [ConciergeMessageType.fromJson]:
/// ```dart
/// final myType = ConciergeMessageType.fromJson('myCustomType');
/// ```
sealed class ConciergeMessageType {
  /// Creates a [ConciergeMessageType] with the given string [value].
  const ConciergeMessageType(this.value);

  /// Deserialises a [ConciergeMessageType] from a string.
  ///
  /// Returns the canonical constant for known values; unknown values are
  /// wrapped in an opaque instance that preserves the original string.
  factory ConciergeMessageType.fromJson(String json) => switch (json) {
    'permissionToUpdateProfile' => permissionToUpdateProfile,
    'permissionToJoinGroup' => permissionToJoinGroup,
    _ => _CustomConciergeMessageType(json),
  };

  /// The string identifier for this type.
  final String value;

  /// Requests permission from the user to update their profile.
  static const permissionToUpdateProfile = _PermissionToUpdateProfile();

  /// Requests permission to join a group chat.
  static const permissionToJoinGroup = _PermissionToJoinGroup();

  @override
  bool operator ==(Object other) =>
      other is ConciergeMessageType && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class _PermissionToUpdateProfile extends ConciergeMessageType {
  const _PermissionToUpdateProfile() : super('permissionToUpdateProfile');
}

final class _PermissionToJoinGroup extends ConciergeMessageType {
  const _PermissionToJoinGroup() : super('permissionToJoinGroup');
}

final class _CustomConciergeMessageType extends ConciergeMessageType {
  const _CustomConciergeMessageType(super.value);
}

class _ConciergeMessageTypeConverter
    extends JsonConverter<ConciergeMessageType, String> {
  const _ConciergeMessageTypeConverter();

  @override
  ConciergeMessageType fromJson(String json) =>
      ConciergeMessageType.fromJson(json);

  @override
  String toJson(ConciergeMessageType object) => object.value;
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
  @_ConciergeMessageTypeConverter()
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
