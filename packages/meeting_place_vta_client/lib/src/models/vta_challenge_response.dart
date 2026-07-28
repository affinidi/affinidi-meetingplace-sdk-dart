import 'package:json_annotation/json_annotation.dart';
import '../errors/vta_client_exception.dart';

part 'vta_challenge_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VtaChallengeResponse {
  const VtaChallengeResponse({
    required this.challenge,
    required this.sessionId,
    required this.expiresAt,
    this.teeAttestation,
  });

  final String challenge;
  final String sessionId;
  final DateTime expiresAt;
  final Map<String, dynamic>? teeAttestation;

  factory VtaChallengeResponse.fromJson(Map<String, dynamic> json) {
    return VtaChallengeResponse(
      challenge: _getRequiredString(json, ['challenge']),
      sessionId: _getRequiredString(json, ['sessionId', 'session_id']),
      expiresAt: _getRequiredDateTime(json, ['expiresAt', 'expires_at']),
      teeAttestation: _getOptionalObject(
        json,
        ['teeAttestation', 'tee_attestation'],
      ),
    );
  }

  Map<String, dynamic> toJson() => _$VtaChallengeResponseToJson(this);
}

String _getRequiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  throw VtaParseException(
    'Missing required string field ${keys.first}.',
    code: 'e.vta.auth.invalid_payload',
  );
}

DateTime _getRequiredDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _getRequiredString(json, keys);
  try {
    return DateTime.parse(value).toUtc();
  } on FormatException catch (error) {
    throw VtaParseException(
      'Invalid timestamp for ${keys.first}.',
      code: 'e.vta.auth.invalid_payload',
      originalMessage: error.message,
    );
  }
}

Map<String, dynamic>? _getOptionalObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw VtaParseException(
      'Invalid object field $key.',
      code: 'e.vta.auth.invalid_payload',
    );
  }
  return null;
}
