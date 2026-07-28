import 'dart:convert';

import '../auth/auth_protocol.dart';
import '../client/vta_client.dart';
import '../errors/vta_client_exception.dart';

class VtaStepUpApprovalResult {
  const VtaStepUpApprovalResult({
    required this.sessionId,
    this.grantedAcr,
    this.rawResponse = const <String, dynamic>{},
  });

  final String sessionId;
  final String? grantedAcr;
  final Map<String, dynamic> rawResponse;
}

typedef VtaStepUpSubmitDocument = Future<String> Function(String document);

class VtaStepUpApprovalOperation {
  VtaStepUpApprovalOperation({
    required this.holderDid,
    required this.vtaDid,
    required this._signer,
    required this._submit,
    DateTime Function()? clock,
  }) : _clock = clock ?? _defaultClock;

  factory VtaStepUpApprovalOperation.forClient({
    required VtaClient client,
    required String holderDid,
    required String vtaDid,
    required VtaAuthSigner signer,
    required String accessToken,
    DateTime Function()? clock,
  }) {
    return VtaStepUpApprovalOperation(
      holderDid: holderDid,
      vtaDid: vtaDid,
      signer: signer,
      clock: clock,
      submit: (document) {
        return client.postText(
          '/api/trust-tasks',
          body: document,
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        );
      },
    );
  }

  factory VtaStepUpApprovalOperation.withTokenProvider({
    required VtaClient client,
    required String holderDid,
    required String vtaDid,
    required VtaAuthSigner signer,
    required Future<String> Function() tokenProvider,
    DateTime Function()? clock,
  }) {
    return VtaStepUpApprovalOperation(
      holderDid: holderDid,
      vtaDid: vtaDid,
      signer: signer,
      clock: clock,
      submit: (document) async {
        final token = await tokenProvider();
        return client.postText(
          '/api/trust-tasks',
          body: document,
          headers: <String, String>{'Authorization': 'Bearer $token'},
        );
      },
    );
  }

  final String holderDid;
  final String vtaDid;
  final VtaAuthSigner _signer;
  final VtaStepUpSubmitDocument _submit;
  final DateTime Function() _clock;

  Future<VtaStepUpApprovalResult> approve({
    required Map<String, dynamic> approveRequest,
    String grantedAcr = 'aal2',
  }) async {
    final sessionId = approveRequest['sessionId']?.toString();
    final challenge = approveRequest['challenge']?.toString();
    final subject = approveRequest['subject']?.toString();

    if (sessionId == null || sessionId.isEmpty) {
      throw const VtaValidationException(
        'approveRequest.sessionId is required.',
        code: 'e.vta.stepup.invalid_approve_request',
      );
    }
    if (challenge == null || challenge.isEmpty) {
      throw const VtaValidationException(
        'approveRequest.challenge is required.',
        code: 'e.vta.stepup.invalid_approve_request',
      );
    }
    if (subject == null || subject.isEmpty) {
      throw const VtaValidationException(
        'approveRequest.subject is required.',
        code: 'e.vta.stepup.invalid_approve_request',
      );
    }

    final id = 'urn:uuid:${_clock().toUtc().microsecondsSinceEpoch}';
    final document = <String, dynamic>{
      'id': id,
      'type': 'https://trusttasks.org/spec/auth/step-up/approve-response/0.1',
      'issuer': holderDid,
      'recipient': vtaDid,
      'issuedAt': _clock().toUtc().toIso8601String(),
      'payload': <String, dynamic>{
        'decision': 'approved',
        'subject': subject,
        'sessionId': sessionId,
        'challenge': challenge,
        'grantedAcr': grantedAcr,
      },
    };

    final proof = await _signer.createProof(
      trustTask: document,
      operation: 'step-up-approve',
    );
    final signed = <String, dynamic>{...document, 'proof': proof};

    late String responseBody;
    try {
      responseBody = await _submit(jsonEncode(signed));
    } catch (e) {
      rethrow;
    }

    final response = _decodeJsonObject(responseBody);
    final payload = _extractPayload(response);
    final session = _decodeObject(payload['session']);

    return VtaStepUpApprovalResult(
      sessionId: session['session_id']?.toString() ?? sessionId,
      grantedAcr:
          session['acr']?.toString() ?? payload['grantedAcr']?.toString(),
      rawResponse: response,
    );
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
    final payload = response['payload'];
    if (payload == null) {
      return response;
    }
    return _decodeObject(payload);
  }

  Map<String, dynamic> _decodeJsonObject(String responseBody) {
    final decoded = jsonDecode(responseBody);
    return _decodeObject(decoded);
  }

  Map<String, dynamic> _decodeObject(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, inner) => MapEntry(key.toString(), inner));
    }
    throw const VtaParseException(
      'Expected JSON object in step-up response.',
      code: 'e.vta.stepup.invalid_response',
    );
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
}
