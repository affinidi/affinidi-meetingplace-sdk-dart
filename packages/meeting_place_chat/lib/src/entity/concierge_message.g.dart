// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'concierge_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConciergeMessage _$ConciergeMessageFromJson(Map<String, dynamic> json) =>
    ConciergeMessage(
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      senderDid: json['senderDid'] as String,
      isFromMe: json['isFromMe'] as bool,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      status: $enumDecode(_$ChatItemStatusEnumMap, json['status']),
      data: json['data'] as Map<String, dynamic>,
      conciergeType: const _ConciergeMessageTypeConverter().fromJson(
        json['conciergeType'] as String,
      ),
      type:
          $enumDecodeNullable(_$ChatItemTypeEnumMap, json['type']) ??
          ChatItemType.conciergeMessage,
    );

Map<String, dynamic> _$ConciergeMessageToJson(ConciergeMessage instance) =>
    <String, dynamic>{
      'chatId': instance.chatId,
      'messageId': instance.messageId,
      'senderDid': instance.senderDid,
      'isFromMe': instance.isFromMe,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'type': _$ChatItemTypeEnumMap[instance.type]!,
      'status': _$ChatItemStatusEnumMap[instance.status]!,
      'data': instance.data,
      'conciergeType': const _ConciergeMessageTypeConverter().toJson(
        instance.conciergeType,
      ),
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
