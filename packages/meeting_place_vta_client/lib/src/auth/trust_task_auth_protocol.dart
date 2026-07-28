import 'dart:convert';

import '../errors/vta_client_exception.dart';
import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import 'auth_models.dart';
import 'auth_protocol.dart';

class TrustTaskVtaAuthProtocol implements VtaAuthProtocol {
  TrustTaskVtaAuthProtocol({
    this.signer,
    this.authenticateProofRequirement = VtaProofRequirement.required,
    this.whoAmIProofRequirement = VtaProofRequirement.required,
  });

  static const String _authenticateType =
      'https://trusttasks.org/spec/auth/authenticate/0.1';
  static const String _refreshType =
      'https://trusttasks.org/spec/auth/refresh/0.1';
  static const String _whoAmIType =
      'https://trusttasks.org/spec/auth/whoami/0.1';

  final VtaAuthSigner? signer;
  final VtaProofRequirement authenticateProofRequirement;
  final VtaProofRequirement whoAmIProofRequirement;

  @override
  Future<String> buildAuthenticateDocument(
    VtaAuthenticateRequest request,
  ) async {
    request.validate();
    final payload = <String, dynamic>{
      'challenge': request.challenge,
      'sessionId': request.sessionId,
      if (request.scopes.isNotEmpty) 'scope': request.scopes,
    };

    final document = _baseDocument(
      id: request.requestId,
      type: _authenticateType,
      issuer: request.holderDid,
      recipient: request.vtaDid,
      issuedAt: request.issuedAt,
      payload: payload,
    );
    final signed = await _applyProofIfRequired(
      document,
      operation: 'authenticate',
      requirement: authenticateProofRequirement,
    );
    return jsonEncode(signed);
  }

  @override
  Future<VtaAuthenticateResult> parseAuthenticateResponse(
    String responseBody,
  ) async {
    final payload = _extractTrustTaskPayloadOrRoot(responseBody);
    return VtaAuthenticateResult.fromJson(payload);
  }

  @override
  Future<String> buildRefreshDocument(VtaRefreshRequest request) async {
    request.validate();

    final payload = <String, dynamic>{
      'refreshToken': request.refreshToken,
      if (request.scopes.isNotEmpty) 'scope': request.scopes,
    };

    return jsonEncode(
      _baseDocument(
        id: request.requestId,
        type: _refreshType,
        issuer: request.holderDid,
        recipient: request.vtaDid,
        issuedAt: request.issuedAt,
        payload: payload,
      ),
    );
  }

  @override
  Future<VtaAuthenticateResult> parseRefreshResponse(
    String responseBody,
  ) async {
    final payload = _extractTrustTaskPayloadOrRoot(responseBody);
    return VtaAuthenticateResult.fromJson(payload);
  }

  @override
  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request) async {
    request.validate();
    final document = _baseDocument(
      id: request.requestId,
      type: _whoAmIType,
      issuer: request.holderDid,
      recipient: request.vtaDid,
      issuedAt: request.issuedAt,
      payload: <String, dynamic>{},
    );
    final signed = await _applyProofIfRequired(
      document,
      operation: 'whoami',
      requirement: whoAmIProofRequirement,
    );
    return jsonEncode(signed);
  }

  @override
  Future<SessionInfo> parseWhoAmIResponse(String responseBody) async {
    final payload = _extractTrustTaskPayloadOrRoot(responseBody);
    final sessionObject = _asObject(payload['session'], field: 'session');
    final roles = _asStringList(payload['roles'], field: 'roles');
    final scopes = _asStringList(payload['scopes'], field: 'scopes');

    final merged = <String, dynamic>{
      ...sessionObject,
      'roles': ?roles,
      'scopes': ?scopes,
    };
    return SessionInfo.fromJson(merged);
  }

  Map<String, dynamic> _baseDocument({
    required String id,
    required String type,
    required String issuer,
    required String recipient,
    required DateTime issuedAt,
    required Map<String, dynamic> payload,
  }) {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'issuer': issuer,
      'recipient': recipient,
      'issuedAt': issuedAt.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  Future<Map<String, dynamic>> _applyProofIfRequired(
    Map<String, dynamic> document, {
    required String operation,
    required VtaProofRequirement requirement,
  }) async {
    if (requirement == VtaProofRequirement.none) {
      return document;
    }

    final authSigner = signer;
    if (authSigner == null) {
      throw VtaProofException(
        'A signer is required for $operation.',
        code: 'e.vta.auth.signer_required',
      );
    }

    final proof = await authSigner.createProof(
      trustTask: document,
      operation: operation,
    );
    if (proof.isEmpty) {
      throw const VtaProofException(
        'Signer returned an empty proof object.',
        code: 'e.vta.auth.invalid_proof',
      );
    }

    return <String, dynamic>{...document, 'proof': proof};
  }

  Map<String, dynamic> _extractTrustTaskPayloadOrRoot(String responseBody) {
    final decoded = jsonDecode(responseBody);
    final root = _asObject(decoded, field: 'response');
    final payload = root['payload'];
    if (payload == null) {
      return root;
    }
    return _asObject(payload, field: 'payload');
  }

  Map<String, dynamic> _asObject(dynamic value, {required String field}) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, innerValue) {
        return MapEntry(key.toString(), innerValue);
      });
    }
    throw VtaParseException(
      'Expected JSON object for $field.',
      code: 'e.vta.auth.invalid_payload',
    );
  }

  List<String>? _asStringList(dynamic value, {required String field}) {
    if (value == null) {
      return null;
    }
    if (value is List) {
      return value
          .map((item) {
            if (item is String) {
              return item;
            }
            throw VtaParseException(
              'Expected all values in $field to be strings.',
              code: 'e.vta.auth.invalid_payload',
            );
          })
          .toList(growable: false);
    }
    throw VtaParseException(
      'Expected list for $field.',
      code: 'e.vta.auth.invalid_payload',
    );
  }

  @override
  String toString() => 'TrustTaskVtaAuthProtocol()';
}
