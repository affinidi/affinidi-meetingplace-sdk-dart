// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventMessage _$EventMessageFromJson(Map<String, dynamic> json) => EventMessage(
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      senderDid: json['senderDid'] as String,
      isFromMe: json['isFromMe'] as bool,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      status: $enumDecode(_$ChatItemStatusEnumMap, json['status']),
      eventType: $enumDecode(_$EventMessageTypeEnumMap, json['eventType']),
      data: json['data'] as Map<String, dynamic>,
      type: $enumDecodeNullable(_$ChatItemTypeEnumMap, json['type']) ??
          ChatItemType.eventMessage,
    );

Map<String, dynamic> _$EventMessageToJson(EventMessage instance) =>
    <String, dynamic>{
      'chatId': instance.chatId,
      'messageId': instance.messageId,
      'senderDid': instance.senderDid,
      'isFromMe': instance.isFromMe,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'type': _$ChatItemTypeEnumMap[instance.type]!,
      'status': _$ChatItemStatusEnumMap[instance.status]!,
      'eventType': _$EventMessageTypeEnumMap[instance.eventType]!,
      'data': instance.data,
    };

const _$ChatItemStatusEnumMap = {
  ChatItemStatus.queued: 'queued',
  ChatItemStatus.sent: 'sent',
  ChatItemStatus.delivered: 'delivered',
  ChatItemStatus.received: 'received',
  ChatItemStatus.error: 'error',
  ChatItemStatus.userInput: 'userInput',
  ChatItemStatus.confirmed: 'confirmed',
};

const _$EventMessageTypeEnumMap = {
  EventMessageType.awaitingGroupMemberToJoin: 'awaitingGroupMemberToJoin',
  EventMessageType.groupDeleted: 'groupDeleted',
  EventMessageType.groupMemberJoinedGroup: 'groupMemberJoinedGroup',
  EventMessageType.groupMemberLeftGroup: 'groupMemberLeftGroup',
};

const _$ChatItemTypeEnumMap = {
  ChatItemType.message: 'message',
  ChatItemType.conciergeMessage: 'conciergeMessage',
  ChatItemType.eventMessage: 'eventMessage',
};
