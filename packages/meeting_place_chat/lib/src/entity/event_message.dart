import 'package:json_annotation/json_annotation.dart';
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

  static const awaitingGroupMemberToJoin = _AwaitingGroupMemberToJoin();
  static const groupDeleted = _GroupDeleted();
  static const groupMemberJoinedGroup = _GroupMemberJoinedGroup();
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

class _EventMessageTypeConverter
    extends JsonConverter<EventMessageType, String> {
  const _EventMessageTypeConverter();

  @override
  EventMessageType fromJson(String json) => EventMessageType.fromJson(json);

  @override
  String toJson(EventMessageType object) => object.value;
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EventMessage extends ChatItem {
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return _$EventMessageFromJson(json);
  }

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

  @_EventMessageTypeConverter()
  final EventMessageType eventType;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() {
    return _$EventMessageToJson(this);
  }
}
