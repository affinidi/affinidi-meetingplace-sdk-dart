// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  chatId: json['chatId'] as String,
  messageId: json['messageId'] as String,
  senderDid: json['senderDid'] as String,
  isFromMe: json['isFromMe'] as bool,
  dateCreated: DateTime.parse(json['dateCreated'] as String),
  status: $enumDecode(_$ChatItemStatusEnumMap, json['status']),
  type:
      $enumDecodeNullable(_$ChatItemTypeEnumMap, json['type']) ??
      ChatItemType.message,
  value: json['value'] as String,
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  reactions:
      (json['reactions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'chatId': instance.chatId,
  'messageId': instance.messageId,
  'senderDid': instance.senderDid,
  'isFromMe': instance.isFromMe,
  'dateCreated': instance.dateCreated.toIso8601String(),
  'type': _$ChatItemTypeEnumMap[instance.type]!,
  'status': _$ChatItemStatusEnumMap[instance.status]!,
  'value': instance.value,
  'attachments': instance.attachments.map((e) => e.toJson()).toList(),
  'reactions': instance.reactions,
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

const _$ChatItemTypeEnumMap = {
  ChatItemType.message: 'message',
  ChatItemType.conciergeMessage: 'conciergeMessage',
  ChatItemType.eventMessage: 'eventMessage',
};
