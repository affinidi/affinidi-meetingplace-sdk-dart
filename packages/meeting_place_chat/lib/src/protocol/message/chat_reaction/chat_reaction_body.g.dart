// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_reaction_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatReactionBody _$ChatReactionBodyFromJson(Map<String, dynamic> json) =>
    ChatReactionBody(
      reactions: (json['reactions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      messageId: json['message_id'] as String,
    );

Map<String, dynamic> _$ChatReactionBodyToJson(ChatReactionBody instance) =>
    <String, dynamic>{
      'reactions': instance.reactions,
      'message_id': instance.messageId,
    };
