import 'package:json_annotation/json_annotation.dart';

part 'auth_tokens.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.refreshExpiresIn,
    this.acr,
    this.amr = const <String>[],
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;
  final String? acr;

  @JsonKey(defaultValue: <String>[])
  final List<String> amr;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(_normalizeAuthTokensJson(json));

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);
}

Map<String, dynamic> _normalizeAuthTokensJson(Map<String, dynamic> json) {
  return {
    'access_token': json['access_token'] ?? json['accessToken'],
    'token_type': json['token_type'] ?? json['tokenType'],
    'expires_in': json['expires_in'] ?? json['expiresIn'],
    'refresh_token': json['refresh_token'] ?? json['refreshToken'],
    'refresh_expires_in':
        json['refresh_expires_in'] ?? json['refreshExpiresIn'],
    'acr': json['acr'],
    'amr': json['amr'],
  };
}
