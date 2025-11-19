// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMessageBody _$GroupMessageBodyFromJson(Map<String, dynamic> json) =>
    GroupMessageBody(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      authenticationTag: json['authentication_tag'] as String,
      preCapsule: json['pre_capsule'] as String,
      fromDid: json['from_did'] as String,
      seqNo: (json['seq_no'] as num).toInt(),
    );

Map<String, dynamic> _$GroupMessageBodyToJson(GroupMessageBody instance) =>
    <String, dynamic>{
      'ciphertext': instance.ciphertext,
      'iv': instance.iv,
      'authentication_tag': instance.authenticationTag,
      'pre_capsule': instance.preCapsule,
      'from_did': instance.fromDid,
      'seq_no': instance.seqNo,
    };
