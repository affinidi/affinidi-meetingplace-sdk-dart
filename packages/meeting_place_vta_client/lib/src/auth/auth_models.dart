import 'dart:math';

import '../errors/vta_client_exception.dart';

class VtaChallengeRequest {
  const VtaChallengeRequest({required this.subject, this.purpose});

  final String subject;
  final String? purpose;

  void validate() {
    _requireNonEmpty(subject, field: 'subject');
    if (!subject.startsWith('did:')) {
      throw const VtaValidationException(
        'subject must be a DID.',
        code: 'e.vta.auth.invalid_subject',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    if (purpose != null && purpose!.isNotEmpty) 'purpose': purpose,
  };
}

class VtaAuthenticateRequest {
  VtaAuthenticateRequest({
    required this.requestId,
    required this.holderDid,
    required this.vtaDid,
    required this.issuedAt,
    required this.challenge,
    required this.sessionId,
    this.scopes = const <String>[],
  });

  factory VtaAuthenticateRequest.create({
    required String holderDid,
    required String vtaDid,
    required String challenge,
    required String sessionId,
    List<String> scopes = const <String>[],
    DateTime? issuedAt,
    String? requestId,
  }) {
    return VtaAuthenticateRequest(
      requestId: requestId ?? _createRequestId(),
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt ?? DateTime.now().toUtc(),
      challenge: challenge,
      sessionId: sessionId,
      scopes: List<String>.unmodifiable(scopes),
    );
  }

  final String requestId;
  final String holderDid;
  final String vtaDid;
  final DateTime issuedAt;
  final String challenge;
  final String sessionId;
  final List<String> scopes;

  void validate() {
    _validateDocumentContext(
      requestId: requestId,
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt,
    );
    _requireNonEmpty(challenge, field: 'challenge');
    _requireNonEmpty(sessionId, field: 'sessionId');
  }
}

class VtaRefreshRequest {
  VtaRefreshRequest({
    required this.requestId,
    required this.holderDid,
    required this.vtaDid,
    required this.issuedAt,
    required this.refreshToken,
    this.scopes = const <String>[],
  });

  factory VtaRefreshRequest.create({
    required String holderDid,
    required String vtaDid,
    required String refreshToken,
    List<String> scopes = const <String>[],
    DateTime? issuedAt,
    String? requestId,
  }) {
    return VtaRefreshRequest(
      requestId: requestId ?? _createRequestId(),
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt ?? DateTime.now().toUtc(),
      refreshToken: refreshToken,
      scopes: List<String>.unmodifiable(scopes),
    );
  }

  final String requestId;
  final String holderDid;
  final String vtaDid;
  final DateTime issuedAt;
  final String refreshToken;
  final List<String> scopes;

  void validate() {
    _validateDocumentContext(
      requestId: requestId,
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt,
    );
    _requireNonEmpty(refreshToken, field: 'refreshToken');
  }
}

class VtaWhoAmIRequest {
  VtaWhoAmIRequest({
    required this.requestId,
    required this.holderDid,
    required this.vtaDid,
    required this.issuedAt,
  });

  factory VtaWhoAmIRequest.create({
    required String holderDid,
    required String vtaDid,
    DateTime? issuedAt,
    String? requestId,
  }) {
    return VtaWhoAmIRequest(
      requestId: requestId ?? _createRequestId(),
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt ?? DateTime.now().toUtc(),
    );
  }

  final String requestId;
  final String holderDid;
  final String vtaDid;
  final DateTime issuedAt;

  void validate() {
    _validateDocumentContext(
      requestId: requestId,
      holderDid: holderDid,
      vtaDid: vtaDid,
      issuedAt: issuedAt,
    );
  }
}

void _validateDocumentContext({
  required String requestId,
  required String holderDid,
  required String vtaDid,
  required DateTime issuedAt,
}) {
  _requireNonEmpty(requestId, field: 'requestId');
  if (!requestId.startsWith('urn:uuid:')) {
    throw const VtaValidationException(
      'requestId must be a urn:uuid value.',
      code: 'e.vta.auth.invalid_request_id',
    );
  }

  _requireDid(holderDid, field: 'holderDid');
  _requireDid(vtaDid, field: 'vtaDid');

  if (!issuedAt.isUtc) {
    throw const VtaValidationException(
      'issuedAt must be UTC.',
      code: 'e.vta.auth.invalid_issued_at',
    );
  }
}

void _requireDid(String value, {required String field}) {
  _requireNonEmpty(value, field: field);
  if (!value.startsWith('did:')) {
    throw VtaValidationException(
      '$field must be a DID.',
      code: 'e.vta.auth.invalid_did',
    );
  }
}

void _requireNonEmpty(String value, {required String field}) {
  if (value.trim().isEmpty) {
    throw VtaValidationException(
      '$field is required.',
      code: 'e.vta.auth.invalid_request',
    );
  }
}

String _createRequestId() {
  final random = Random.secure();
  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final suffix = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  return 'urn:uuid:$timestamp-$suffix';
}
