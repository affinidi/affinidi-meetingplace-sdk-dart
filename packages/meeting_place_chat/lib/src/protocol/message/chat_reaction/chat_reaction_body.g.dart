// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_reaction_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatReactionBody _$ChatReactionBodyFromJson(Map<String, dynamic> json) =>
    ChatReactionBody(
      reactions:
          (json['reactions'] as List<dynamic>).map((e) => e as String).toList(),
      messageId: json['messageId'] as String,
    );

Map<String, dynamic> _$ChatReactionBodyToJson(ChatReactionBody instance) =>
    <String, dynamic>{
      'reactions': instance.reactions,
      'messageId': instance.messageId,
    };
