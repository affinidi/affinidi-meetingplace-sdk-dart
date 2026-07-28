import 'package:json_annotation/json_annotation.dart';

part 'session_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SessionInfo {
  const SessionInfo({
    required this.sessionId,
    required this.subject,
    required this.issuedAt,
    required this.expiresAt,
    this.acr,
    this.amr = const <String>[],
    this.roles = const <String>[],
    this.scopes = const <String>[],
  });

  final String sessionId;
  final String subject;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? acr;

  @JsonKey(defaultValue: <String>[])
  final List<String> amr;

  @JsonKey(defaultValue: <String>[])
  final List<String> roles;

  @JsonKey(defaultValue: <String>[])
  final List<String> scopes;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(_normalizeSessionInfoJson(json));

  Map<String, dynamic> toJson() => _$SessionInfoToJson(this);
}

Map<String, dynamic> _normalizeSessionInfoJson(Map<String, dynamic> json) {
  return {
    'session_id': json['session_id'] ?? json['sessionId'] ?? json['id'],
    'subject': json['subject'],
    'issued_at': json['issued_at'] ?? json['issuedAt'],
    'expires_at': json['expires_at'] ?? json['expiresAt'],
    'acr': json['acr'],
    'amr': json['amr'],
    'roles': json['roles'],
    'scopes': json['scopes'],
  };
}
