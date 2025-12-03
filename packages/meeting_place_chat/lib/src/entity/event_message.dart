import 'package:json_annotation/json_annotation.dart';
import 'chat_item.dart';

part 'event_message.g.dart';

enum EventMessageType {
  awaitingGroupMemberToJoin,
  groupDeleted,
  groupMemberJoinedGroup,
  groupMemberLeftGroup,
  personaShared,
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

  final EventMessageType eventType;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() {
    return _$EventMessageToJson(this);
  }
}
