// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMessageBody _$GroupMessageBodyFromJson(Map<String, dynamic> json) =>
    GroupMessageBody(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      authenticationTag: json['authenticationTag'] as String,
      preCapsule: json['preCapsule'] as String,
      fromDid: json['fromDid'] as String,
      seqNo: (json['seqNo'] as num).toInt(),
    );

Map<String, dynamic> _$GroupMessageBodyToJson(GroupMessageBody instance) =>
    <String, dynamic>{
      'ciphertext': instance.ciphertext,
      'iv': instance.iv,
      'authenticationTag': instance.authenticationTag,
      'preCapsule': instance.preCapsule,
      'fromDid': instance.fromDid,
      'seqNo': instance.seqNo,
    };
