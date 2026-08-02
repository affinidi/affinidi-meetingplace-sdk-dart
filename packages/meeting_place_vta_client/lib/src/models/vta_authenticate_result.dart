import 'package:json_annotation/json_annotation.dart';
import '../errors/vta_client_exception.dart';
import 'auth_tokens.dart';
import 'session_info.dart';

part 'vta_authenticate_result.g.dart';

@JsonSerializable(explicitToJson: true)
class VtaAuthenticateResult {
  const VtaAuthenticateResult({required this.tokens, required this.session});

  final AuthTokens tokens;
  final SessionInfo session;

  factory VtaAuthenticateResult.fromJson(Map<String, dynamic> json) {
    final tokensJson = _getRequiredObject(json, ['tokens']);
    final sessionJson = _getRequiredObject(json, ['session']);
    return VtaAuthenticateResult(
      tokens: AuthTokens.fromJson(tokensJson),
      session: SessionInfo.fromJson(sessionJson),
    );
  }

  Map<String, dynamic> toJson() => _$VtaAuthenticateResultToJson(this);

  DateTime get accessExpiresAt =>
      session.issuedAt.add(Duration(seconds: tokens.expiresIn));

  DateTime? get refreshExpiresAt {
    final refreshSeconds = tokens.refreshExpiresIn;
    if (refreshSeconds == null) {
      return null;
    }
    return session.issuedAt.add(Duration(seconds: refreshSeconds));
  }
}

Map<String, dynamic> _getRequiredObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final object = _getOptionalObject(json, keys);
  if (object != null) {
    return object;
  }
  throw VtaParseException(
    'Missing required object field ${keys.first}.',
    code: 'e.vta.auth.invalid_payload',
  );
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
