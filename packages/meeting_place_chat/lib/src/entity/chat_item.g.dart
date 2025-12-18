// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ChatItemToJson(ChatItem instance) => <String, dynamic>{
  'chatId': instance.chatId,
  'messageId': instance.messageId,
  'senderDid': instance.senderDid,
  'isFromMe': instance.isFromMe,
  'dateCreated': instance.dateCreated.toIso8601String(),
  'type': _$ChatItemTypeEnumMap[instance.type]!,
  'status': _$ChatItemStatusEnumMap[instance.status]!,
};

const _$ChatItemTypeEnumMap = {
  ChatItemType.message: 'message',
  ChatItemType.conciergeMessage: 'conciergeMessage',
  ChatItemType.eventMessage: 'eventMessage',
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
