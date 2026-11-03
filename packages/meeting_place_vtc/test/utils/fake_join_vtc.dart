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

  /// The verdict on a submit. [applicant] anywhere in it stands for the DID
  /// that applied.
  Map<String, dynamic> verdict = {
    'effect': 'allow',
    'with': {
      'role': 'member',
      'vmc': {
        'id': 'urn:uuid:vmc',
        'type': ['VerifiableCredential', 'MembershipCredential'],
        'issuer': vtcDid,
        'credentialSubject': {'id': applicant},
      },
      'roleVac': {
        'id': 'urn:uuid:vac',
        'type': ['VerifiableCredential', 'AuthorityCredential'],
        'issuer': vtcDid,
      },
    },
  };

  /// Stands for the applicant's DID in [verdict].
  static const applicant = '<applicant>';
  String status = 'pending';
  Map<String, dynamic>? refusal;

  /// Answers signed by another key than the community's.
  bool signWithOtherKey = false;

  /// Answers threaded on another request.
  bool answerOtherRequest = false;

  final List<Map<String, dynamic>> received = [];

  /// Refusal codes for the next membership confirmations, one per call.
  final List<String> vmcRefusals = [];

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
    if (type == MemberTask.vmc && vmcRefusals.isNotEmpty) {
      return (
        422,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': vtcDid,
          'payload': {'code': vmcRefusals.removeAt(0)},
        },
      );
    }
    final payload = switch (type) {
      JoinTask.manifest => manifest,
      JoinTask.submit => {
        'requestId': 'request-1',
        'verdict': _withApplicant(verdict, request['issuer'] as String),
      },
      JoinTask.status => {
        'requestId': (request['payload'] as Map)['requestId'],
        'status': status,
      },
      MemberTask.vmc => {
        'memberDid': request['issuer'],
        'vmcId': 'urn:uuid:member-vmc',
        'status': 'stored',
        'requestId': ?(request['payload'] as Map)['requestId'],
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

  static dynamic _withApplicant(Object? value, String did) => switch (value) {
    applicant => did,
    final Map<String, dynamic> map => {
      for (final MapEntry(:key, :value) in map.entries)
        key: _withApplicant(value, did),
    },
    final List<dynamic> list => [
      for (final item in list) _withApplicant(item, did),
    ],
    _ => value,
  };
}
