// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_delivered_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatDeliveredBody _$ChatDeliveredBodyFromJson(Map<String, dynamic> json) =>
    ChatDeliveredBody(
      messages:
          (json['messages'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ChatDeliveredBodyToJson(ChatDeliveredBody instance) =>
    <String, dynamic>{
      'messages': instance.messages,
    };
