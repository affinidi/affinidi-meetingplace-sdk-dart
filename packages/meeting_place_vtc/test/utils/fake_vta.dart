import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

const fakeVtaToken = 'access-token';

/// A VTA answering the REST binding, keyed by task type.
///
/// Signs its answers, addressed to the requester and threaded on the
/// request, as a VTA does.
class FakeVta {
  FakeVta() {
    final json = DidKey.resolve(key.did).toJson()
      ..['service'] = [
        {
          'id': '${key.did}#vta-rest',
          'type': 'VTARest',
          'serviceEndpoint': 'https://vta.example/api',
        },
      ];
    document = DidDocument.fromJson(json);
  }

  final key = Ed25519DidKeySigner.generate();
  late final DidDocument document;
  final Map<String, Map<String, dynamic>> answers = {};
  final Map<String, Map<String, dynamic>> refusals = {};
  final List<Map<String, dynamic>> received = [];
  int rejectTokenTimes = 0;

  /// Whether a rejected token is answered with a Trust Task error document,
  /// rather than with the VTA's own JSON error.
  bool rejectTokenWithDocument = false;

  /// Signs answers with this key instead of the VTA's, when set.
  Ed25519DidKeySigner? answerSigner;

  /// Threads answers on this id instead of the request's, when set.
  String? answerThreadId;

  String get did => key.did;

  Future<(int, Object?)> handle(Map<String, dynamic> request) async {
    received.add(request);
    final type = request['type'] as String;
    if (type == VtaTask.challenge) {
      return _answer(request, {
        'sessionId': 'session-1',
        'challenge': 'nonce-1',
      });
    }
    if (type == VtaTask.authenticate) {
      return _answer(request, {
        'tokens': {'accessToken': fakeVtaToken},
      });
    }
    if (rejectTokenTimes > 0) {
      rejectTokenTimes--;
      if (!rejectTokenWithDocument) return (401, {'error': 'unauthorized'});
      return (401, _error({'code': 'unauthenticated'}));
    }
    if (refusals[type] case final payload?) {
      return (400, _error(payload));
    }
    return _answer(request, answers[type] ?? const {});
  }

  Map<String, dynamic> _error(Map<String, dynamic> payload) => {
    'id': 'urn:uuid:error',
    'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
    'issuer': did,
    'payload': payload,
  };

  Future<(int, Object?)> _answer(
    Map<String, dynamic> request,
    Map<String, dynamic> payload,
  ) async {
    final signer = answerSigner ?? key;
    final answer = await TrustTaskDocument.create(
      type: '${request['type']}#response',
      issuer: signer.did,
      recipient: request['issuer'] as String,
      threadId: answerThreadId ?? request['id'] as String,
      payload: payload,
    ).sign(signer, purpose: ProofPurpose.authentication);
    return (200, answer.toJson());
  }
}
