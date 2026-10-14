import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

const fakeVtaToken = 'access-token';

/// A VTA answering the REST binding, keyed by task type.
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

  String get did => key.did;

  Future<(int, Object?)> handle(Map<String, dynamic> request) async {
    received.add(request);
    final type = request['type'] as String;
    if (type == VtaTask.challenge) {
      return _answer({'sessionId': 'session-1', 'challenge': 'nonce-1'});
    }
    if (type == VtaTask.authenticate) {
      return _answer({
        'tokens': {'accessToken': fakeVtaToken},
      });
    }
    if (rejectTokenTimes > 0) {
      rejectTokenTimes--;
      return (401, 'Unauthorized');
    }
    if (refusals[type] case final payload?) {
      return (
        400,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': did,
          'payload': payload,
        },
      );
    }
    return _answer(answers[type] ?? const {});
  }

  (int, Object?) _answer(Map<String, dynamic> payload) => (
    200,
    {
      'id': 'urn:uuid:answer',
      'type': 'answer',
      'issuer': did,
      'payload': payload,
    },
  );
}
