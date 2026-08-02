// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vta_challenge_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VtaChallengeResponse _$VtaChallengeResponseFromJson(
  Map<String, dynamic> json,
) => VtaChallengeResponse(
  challenge: json['challenge'] as String,
  sessionId: json['session_id'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  teeAttestation: json['tee_attestation'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$VtaChallengeResponseToJson(
  VtaChallengeResponse instance,
) => <String, dynamic>{
  'challenge': instance.challenge,
  'session_id': instance.sessionId,
  'expires_at': instance.expiresAt.toIso8601String(),
  'tee_attestation': instance.teeAttestation,
};
