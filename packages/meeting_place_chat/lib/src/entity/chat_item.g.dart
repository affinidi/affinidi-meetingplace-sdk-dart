// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatItem _$ChatItemFromJson(Map<String, dynamic> json) => ChatItem(
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      senderDid: json['senderDid'] as String,
      isFromMe: json['isFromMe'] as bool,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      status: $enumDecode(_$ChatItemStatusEnumMap, json['status']),
      type: $enumDecode(_$ChatItemTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$ChatItemToJson(ChatItem instance) => <String, dynamic>{
      'chatId': instance.chatId,
      'messageId': instance.messageId,
      'senderDid': instance.senderDid,
      'isFromMe': instance.isFromMe,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'type': _$ChatItemTypeEnumMap[instance.type]!,
      'status': _$ChatItemStatusEnumMap[instance.status]!,
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
