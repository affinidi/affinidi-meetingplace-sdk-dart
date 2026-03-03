import 'package:json_annotation/json_annotation.dart';
import 'chat_item.dart';

part 'event_message.g.dart';

/// Defines the type of event message sent in a group chat.
///
/// The SDK provides built-in types as named constants, but consumers
/// can define their own by constructing instances:
/// ```dart
/// const myType = EventMessageType('myCustomType');
/// ```
class EventMessageType {
  /// Creates an [EventMessageType] with the given string [value].
  const EventMessageType(this.value);

  /// The string identifier for this type.
  final String value;

  static const awaitingGroupMemberToJoin =
      EventMessageType('awaitingGroupMemberToJoin');
  static const groupDeleted = EventMessageType('groupDeleted');
  static const groupMemberJoinedGroup =
      EventMessageType('groupMemberJoinedGroup');
  static const groupMemberLeftGroup = EventMessageType('groupMemberLeftGroup');

  @override
  bool operator ==(Object other) =>
      other is EventMessageType && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class _EventMessageTypeConverter
    extends JsonConverter<EventMessageType, String> {
  const _EventMessageTypeConverter();

  @override
  EventMessageType fromJson(String json) => EventMessageType(json);

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
