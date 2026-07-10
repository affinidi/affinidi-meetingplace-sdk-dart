import 'package:vta_dart_client/vta_dart_client.dart';

String requiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  throw VtaParseException(
    'Missing required string field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}

bool requiredBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }
  throw VtaParseException(
    'Missing required bool field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}

Map<String, dynamic> requiredObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  throw VtaParseException(
    'Missing required object field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}
