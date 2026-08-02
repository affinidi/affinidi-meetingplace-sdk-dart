// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => SessionInfo(
  sessionId: json['session_id'] as String,
  subject: json['subject'] as String,
  issuedAt: DateTime.parse(json['issued_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  acr: json['acr'] as String?,
  amr: (json['amr'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  scopes:
      (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$SessionInfoToJson(SessionInfo instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'subject': instance.subject,
      'issued_at': instance.issuedAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'acr': instance.acr,
      'amr': instance.amr,
      'roles': instance.roles,
      'scopes': instance.scopes,
    };
