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

  /// The profile `GET <base>/community/public-profile` answers.
  Map<String, dynamic> publicProfile = {
    'communityDid': vtcDid,
    'name': 'Football club',
    'description': 'Five-a-side on Sundays.',
    'logoUrl': 'https://club.example/logo.png',
    'publicUrl': 'https://club.example/',
    'contactEmail': 'hello@club.example',
    'language': 'en',
    'createdAt': '2026-11-03T10:19:24Z',
    'personhood': {'realHuman': true, 'singleMembership': false},
  };

  /// Answers a `GET` for the public profile, and nothing else.
  Future<(int, Object?)> handleGet(Uri uri) async =>
      uri.path.endsWith('/community/public-profile')
      ? (200, publicProfile)
      : (404, {'error': 'not found'});

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

  /// The reason a rejected request's status gives.
  String? rejectionReason;
  Map<String, dynamic>? refusal;

  /// Answers signed by another key than the community's.
  bool signWithOtherKey = false;

  /// Answers threaded on another request.
  bool answerOtherRequest = false;

  final List<Map<String, dynamic>> received = [];

  /// Answers to other tasks, by type, from the request's payload.
  final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
  answerTo = {};

  /// Refusal codes for the next membership confirmations, one per call.
  final List<String> vmcRefusals = [];

  /// The code to refuse the next withdraw with, if any.
  String? withdrawRefusal;

  /// Answers a withdraw with a status other than `withdrawn`.
  bool withdrawNotWithdrawn = false;

  /// The HTTP status and code to refuse the next leave with, if any.
  (int, String)? leaveRefusal;

  /// Answers a leave for a DID other than the one that left.
  bool leaveReceiptForOther = false;

  /// The cards a renewal answers with. [applicant] stands for the renewing
  /// DID.
  Map<String, dynamic> renewal = {
    'vmc': {
      'id': 'urn:uuid:vmc-2',
      'type': ['VerifiableCredential', 'MembershipCredential'],
      'issuer': vtcDid,
      'credentialSubject': {'id': applicant},
    },
    'roleVac': {
      'id': 'urn:uuid:vac-2',
      'type': ['VerifiableCredential', 'AuthorityCredential'],
      'issuer': vtcDid,
    },
  };

  /// Answers a renewal for a DID other than the one that asked.
  bool renewalForOther = false;

  /// The pages a vetter listing answers with, the next one per call; each
  /// but the last names a `nextCursor`. None answers without vetters.
  List<List<Map<String, dynamic>>> vetterPages = [[]];
  int _vetterPage = 0;

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
    if (type == MemberTask.selfRemove && leaveRefusal != null) {
      final (status, code) = leaveRefusal!;
      return (
        status,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': vtcDid,
          'payload': {'code': code},
        },
      );
    }
    if (type == JoinTask.withdraw && withdrawRefusal != null) {
      return (
        404,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': vtcDid,
          'payload': {'code': withdrawRefusal},
        },
      );
    }
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
        'reason': ?rejectionReason,
        if (status == 'approved') 'credentialsDelivered': false,
      },
      JoinTask.withdraw => {
        'requestId': (request['payload'] as Map)['requestId'],
        'status': withdrawNotWithdrawn ? 'pending' : 'withdrawn',
      },
      MemberTask.directoryCardUpdate => {'revision': 1},
      MemberTask.selfRemove => {
        'did': leaveReceiptForOther ? 'did:key:other' : request['issuer'],
        'disposition': 'tombstone',
        'removed': true,
      },
      MemberTask.vmc => {
        'memberDid': request['issuer'],
        'vmcId': 'urn:uuid:member-vmc',
        'status': 'stored',
        'requestId': ?(request['payload'] as Map)['requestId'],
      },
      MemberTask.renew => {
        'did': renewalForOther ? 'did:key:other' : request['issuer'],
        ..._withApplicant(renewal, request['issuer'] as String)
            as Map<String, dynamic>,
        'personhood': false,
        'personhoodChanged': false,
      },
      VettingCommunityTask.vettersList when vetterPages.isEmpty =>
        <String, dynamic>{},
      VettingCommunityTask.vettersList => {
        'vetters': vetterPages[_vetterPage],
        if (++_vetterPage < vetterPages.length) 'nextCursor': 'page-2',
      },
      _ =>
        answerTo[type]?.call(request['payload'] as Map<String, dynamic>) ??
            (throw StateError('unexpected task')),
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
