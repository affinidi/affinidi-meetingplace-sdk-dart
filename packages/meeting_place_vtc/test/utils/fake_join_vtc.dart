import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

import 'fake_vtc.dart';

/// A community that answers `vtc/join-requests` tasks like a VTC, signing
/// each answer for authentication.
class FakeJoinVtc {
  FakeJoinVtc({bool signInPortal = true}) {
    didDocument = communityDocument(_signer, signInPortal: signInPortal);
  }

  final _signer = communitySigner();
  late final DidDocument didDocument;

  Map<String, dynamic> manifest = {
    'communityDid': vtcDid,
    'branding': {'displayName': 'Football club'},
    'criteria': [
      {'id': 'open', 'admission': 'automatic', 'requirementsDigest': 'z1'},
      {
        'id': 'invited',
        'admission': 'automatic',
        'requirementsDigest': 'z2',
        'invitationRequired': true,
      },
    ],
  };
  Map<String, dynamic> verdict = {
    'effect': 'allow',
    'with': {
      'role': 'member',
      'vmc': {'id': 'urn:uuid:vmc', 'type': 'MembershipCredential'},
      'roleVac': {'id': 'urn:uuid:vac', 'type': 'AuthorityCredential'},
    },
  };
  String status = 'pending';
  Map<String, dynamic>? refusal;

  /// Answers signed by another key than the community's.
  bool signWithOtherKey = false;

  /// Answers threaded on another request.
  bool answerOtherRequest = false;

  final List<Map<String, dynamic>> received = [];

  Future<(int, Object?)> handle(Map<String, dynamic> request) async {
    received.add(request);
    if (refusal case final payload?) {
      return (
        409,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': vtcDid,
          'payload': payload,
        },
      );
    }

    final type = request['type'] as String;
    final payload = switch (type) {
      JoinTask.manifest => manifest,
      JoinTask.submit => {'requestId': 'request-1', 'verdict': verdict},
      JoinTask.status => {
        'requestId': (request['payload'] as Map)['requestId'],
        'status': status,
      },
      _ => throw StateError('unexpected task'),
    };

    final signer = signWithOtherKey
        ? NamedSigner(
            vtcDid,
            '$vtcDid#key-0',
            Ed25519DidKeySigner.generate().seed,
          )
        : _signer;
    final answer = await TrustTaskDocument.create(
      type: '$type#response',
      issuer: vtcDid,
      recipient: request['issuer'] as String,
      threadId: answerOtherRequest ? 'urn:uuid:other' : request['id'] as String,
      payload: payload,
    ).sign(signer, purpose: ProofPurpose.authentication);
    return (200, answer.toJson());
  }
}
