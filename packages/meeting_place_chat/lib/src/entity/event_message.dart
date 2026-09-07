import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'chat_item.dart';

part 'event_message.g.dart';

/// Defines the type of an event message in a group chat.
///
/// Built-in types are exposed as named constants. Custom application-specific
/// types can be created via [EventMessageType.fromJson]:
/// ```dart
/// final myType = EventMessageType.fromJson('myCustomType');
/// ```
sealed class EventMessageType {
  /// Creates an [EventMessageType] with the given string [value].
  const EventMessageType(this.value);

  /// Deserialises an [EventMessageType] from a string.
  ///
  /// Returns the canonical constant for known values; unknown values are
  /// wrapped in an opaque instance that preserves the original string.
  factory EventMessageType.fromJson(String json) => switch (json) {
    'awaitingGroupMemberToJoin' => awaitingGroupMemberToJoin,
    'groupDeleted' => groupDeleted,
    'groupMemberJoinedGroup' => groupMemberJoinedGroup,
    'groupMemberLeftGroup' => groupMemberLeftGroup,
    _ => _CustomEventMessageType(json),
  };

  /// The string identifier for this type.
  final String value;

  /// The SDK is awaiting a member to join the group.
  static const awaitingGroupMemberToJoin = _AwaitingGroupMemberToJoin();

  /// The group was deleted.
  static const groupDeleted = _GroupDeleted();

  /// A member joined the group.
  static const groupMemberJoinedGroup = _GroupMemberJoinedGroup();

  /// A member left the group.
  static const groupMemberLeftGroup = _GroupMemberLeftGroup();

  @override
  bool operator ==(Object other) =>
      other is EventMessageType && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class _AwaitingGroupMemberToJoin extends EventMessageType {
  const _AwaitingGroupMemberToJoin() : super('awaitingGroupMemberToJoin');
}

final class _GroupDeleted extends EventMessageType {
  const _GroupDeleted() : super('groupDeleted');
}

final class _GroupMemberJoinedGroup extends EventMessageType {
  const _GroupMemberJoinedGroup() : super('groupMemberJoinedGroup');
}

final class _GroupMemberLeftGroup extends EventMessageType {
  const _GroupMemberLeftGroup() : super('groupMemberLeftGroup');
}

final class _CustomEventMessageType extends EventMessageType {
  const _CustomEventMessageType(super.value);
}

/// Why a member is no longer part of a group.
enum GroupMemberLeaveReason {
  /// Indicates the group member left voluntarily.
  leave,

  /// Indicates the group member was removed by another party.
  kick;

  /// Deserialises a [GroupMemberLeaveReason] from its [name].
  ///
  /// Falls back to [leave] for `null` or unrecognized values.
  static GroupMemberLeaveReason fromJson(String? json) {
    return values.firstWhere(
      (reason) => reason.name == json,
      orElse: () => GroupMemberLeaveReason.leave,
    );
  }
}

class _EventMessageTypeConverter
    extends JsonConverter<EventMessageType, String> {
  const _EventMessageTypeConverter();

  @override
  EventMessageType fromJson(String json) => EventMessageType.fromJson(json);

  @override
  String toJson(EventMessageType object) => object.value;
}

/// [EventMessage] is a special type of [ChatItem] used to represent
/// group lifecycle notifications rendered inline in the chat.
///
/// Examples include:
/// - A member joining or leaving a group.
/// - Awaiting a member to join a group.
/// - A group being deleted.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EventMessage extends ChatItem {
  /// Factory constructor to create an [EventMessage] from JSON.
  ///
  /// [json] is the JSON map containing serialized [EventMessage] data.
  /// Returns a new [EventMessage] instance.
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return _$EventMessageFromJson(json);
  }

  /// Creates a new [EventMessage].
  ///
  /// [chatId] is the unique identifier of the chat this message belongs to.
  /// [messageId] is the unique identifier of the message within the chat.
  /// [senderDid] is the DID of the user who sent the message. [isFromMe]
  /// indicates whether the message was sent by the current user.
  /// [dateCreated] is the timestamp indicating when the message was
  /// created, in UTC. [status] is the current status of the message.
  /// [eventType] is the [EventMessageType] of this message. [data] is
  /// additional structured metadata for the event. [type] is always set to
  /// [ChatItemType.eventMessage].
  EventMessage({
    required super.chatId,
    required super.messageId,
    required super.senderDid,
    required super.isFromMe,
    required super.dateCreated,
    required super.status,
    required this.eventType,
    required this.data,
    super.type = ChatItemType.eventMessage,
  });

  /// Records that [memberDid] joined the group identified by [groupDid].
  factory EventMessage.groupMemberJoined({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required Map<String, dynamic> memberCard,
  }) => EventMessage._groupMember(
    type: EventMessageType.groupMemberJoinedGroup,
    chatId: chatId,
    groupDid: groupDid,
    memberDid: memberDid,
    memberCard: memberCard,
  );

  /// Records that [memberDid] left the group identified by [groupDid].
  factory EventMessage.groupMemberLeft({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required Map<String, dynamic> memberCard,
    GroupMemberLeaveReason reason = GroupMemberLeaveReason.leave,
  }) => EventMessage._groupMember(
    type: EventMessageType.groupMemberLeftGroup,
    chatId: chatId,
    groupDid: groupDid,
    memberDid: memberDid,
    memberCard: memberCard,
    reason: reason,
  );

  /// Records that the SDK is awaiting [memberDid] to join the group.
  factory EventMessage.awaitingGroupMember({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required Map<String, dynamic> memberCard,
  }) => EventMessage._groupMember(
    type: EventMessageType.awaitingGroupMemberToJoin,
    chatId: chatId,
    groupDid: groupDid,
    memberDid: memberDid,
    memberCard: memberCard,
  );

  /// Records that the group identified by [groupDid] was deleted.
  factory EventMessage.groupDeleted({
    required String chatId,
    required String groupDid,
  }) => EventMessage(
    chatId: chatId,
    messageId: const Uuid().v4(),
    senderDid: groupDid,
    eventType: EventMessageType.groupDeleted,
    isFromMe: false,
    dateCreated: DateTime.now().toUtc(),
    status: ChatItemStatus.received,
    data: const {},
  );

  factory EventMessage._groupMember({
    required EventMessageType type,
    required String chatId,
    required String groupDid,
    required String memberDid,
    required Map<String, dynamic> memberCard,
    GroupMemberLeaveReason? reason,
  }) => EventMessage(
    chatId: chatId,
    messageId: const Uuid().v4(),
    senderDid: groupDid,
    eventType: type,
    isFromMe: false,
    dateCreated: DateTime.now().toUtc(),
    status: ChatItemStatus.received,
    data: {
      'memberDid': memberDid,
      'contactCard': memberCard,
      if (reason != null) 'reason': reason.name,
    },
  );

  /// Type of event message.
  @_EventMessageTypeConverter()
  final EventMessageType eventType;

  /// Structured metadata payload for the event (e.g. `memberDid`,
  /// `contactCard`, `reason`).
  final Map<String, dynamic> data;

  /// Serializes the [EventMessage] into a JSON object.
  ///
  /// Returns a `Map<String, dynamic>` representation of the message.
  @override
  Map<String, dynamic> toJson() {
    return _$EventMessageToJson(this);
  }
}
