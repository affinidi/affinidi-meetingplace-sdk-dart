// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oob_connection_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OobConnectionMessage _$OobConnectionMessageFromJson(
  Map<String, dynamic> json,
) => OobConnectionMessage(
  id: json['id'] as String,
  from: json['from'] as String,
  to: (json['to'] as List<dynamic>).map((e) => e as String).toList(),
  body: json['body'] as Map<String, dynamic>,
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdTime: json['createdTime'] == null
      ? null
      : DateTime.parse(json['createdTime'] as String),
);

Map<String, dynamic> _$OobConnectionMessageToJson(
  OobConnectionMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'from': instance.from,
  'to': instance.to,
  'body': instance.body,
  'createdTime': instance.createdTime.toIso8601String(),
  'attachments': ?instance.attachments?.map((e) => e.toJson()).toList(),
};
