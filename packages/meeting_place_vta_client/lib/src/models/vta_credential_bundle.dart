import 'dart:convert';

import '../errors/vta_client_exception.dart';

class VtaCredentialBundle {
  const VtaCredentialBundle({
    required this.did,
    required this.vtaUrl,
    required this.privateKeyMultibase,
    this.contextId,
    this.keyId,
    this.raw = const {},
  });

  final String did;
  final String vtaUrl;
  final String privateKeyMultibase;
  final String? contextId;
  final String? keyId;
  final Map<String, dynamic> raw;

  factory VtaCredentialBundle.fromJson(Map<String, dynamic> json) {
    final did = _firstRequiredString(
      json,
      ['did', 'holder_did'],
      fieldName: 'did',
    );
    final vtaUrl = _firstRequiredString(
      json,
      ['vta_url', 'url', 'base_url'],
      fieldName: 'vta_url',
    );
    final privateKey = _firstRequiredString(
      json,
      ['private_key_multibase', 'privateKeyMultibase'],
      fieldName: 'private_key_multibase',
    );

    return VtaCredentialBundle(
      did: did,
      vtaUrl: vtaUrl,
      privateKeyMultibase: privateKey,
      contextId: _firstOptionalString(json, ['context_id', 'context']),
      keyId: _firstOptionalString(json, ['key_id', 'keyId']),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  factory VtaCredentialBundle.parse(String base64UrlValue) {
    final trimmed = base64UrlValue.trim();
    if (trimmed.isEmpty) {
      throw const VtaValidationException(
        'Credential bundle must not be empty.',
        code: 'e.vta.credential.empty',
      );
    }

    late String decoded;
    try {
      final normalized = base64.normalize(trimmed);
      decoded = utf8.decode(base64Url.decode(normalized));
    } on FormatException catch (error) {
      throw VtaParseException(
        'Credential bundle is not valid base64url.',
        code: 'e.vta.credential.invalid_base64url',
        originalMessage: error.message,
      );
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(decoded);
    } on FormatException catch (error) {
      throw VtaParseException(
        'Credential bundle decoded content is not valid JSON.',
        code: 'e.vta.credential.invalid_json',
        originalMessage: error.message,
      );
    }

    return VtaCredentialBundle.fromJson(
      _asObject(parsed, fieldName: 'credential_bundle'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'vta_url': vtaUrl,
      'private_key_multibase': privateKeyMultibase,
      if (contextId != null) 'context_id': contextId,
      if (keyId != null) 'key_id': keyId,
    };
  }

  static String _firstRequiredString(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fieldName,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    throw VtaParseException(
      'Missing required field "$fieldName" in credential bundle.',
      code: 'e.vta.credential.required_field',
    );
  }

  static String? _firstOptionalString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      if (value is String) {
        return value;
      }
      throw VtaParseException(
        'Invalid string field "$key" in credential bundle.',
        code: 'e.vta.credential.invalid_field',
      );
    }
    return null;
  }

  static Map<String, dynamic> _asObject(
    dynamic value, {
    required String fieldName,
  }) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw VtaParseException(
      'Expected object for "$fieldName".',
      code: 'e.vta.parse.object_expected',
    );
  }
}
