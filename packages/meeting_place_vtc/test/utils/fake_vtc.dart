import 'dart:typed_data';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

const vtcDid = 'did:web:community.example';
const vtcOrigin = 'https://community.example';
const fakeNow = 1791460800;

/// Signs as a fixed DID and verification method with an Ed25519 key.
class NamedSigner implements TrustTaskSigner {
  NamedSigner(this.did, this.verificationMethod, Uint8List seed)
    : _key = Ed25519DidKeySigner.fromSeed(seed);

  final Ed25519DidKeySigner _key;

  @override
  final String did;

  @override
  final String verificationMethod;

  Uint8List get publicKey =>
      multiBaseToUint8List(_key.did.substring('did:key:'.length)).sublist(2);

  @override
  Future<Uint8List> sign(Uint8List data) => _key.sign(data);
}

/// A community that answers `auth/oob` tasks like a VTC.
class FakeVtc {
  FakeVtc({this.audience}) {
    final signer = _signer;
    didDocument = DidDocument.fromJson({
      '@context': ['https://www.w3.org/ns/did/v1'],
      'id': vtcDid,
      'verificationMethod': [
        {
          'id': '$vtcDid#key-0',
          'type': 'Multikey',
          'controller': vtcDid,
          'publicKeyMultibase': toMultiBase(
            toMultikey(signer.publicKey, KeyType.ed25519),
          ),
        },
      ],
      'authentication': ['$vtcDid#key-0'],
      'assertionMethod': ['$vtcDid#key-0'],
      'service': [
        {
          'id': '$vtcDid#trust-tasks',
          'type': 'TrustTaskHTTPS',
          'serviceEndpoint': '$vtcOrigin/v1',
        },
        {
          'id': '$vtcDid#sign-in-portal',
          'type': 'SignInPortal',
          'serviceEndpoint': '$vtcOrigin/members/',
        },
      ],
    });
  }

  final _signer = NamedSigner(
    vtcDid,
    '$vtcDid#key-0',
    Uint8List.fromList(List.filled(32, 3)),
  );

  /// The audience echoed in the answers, `admin` for the console.
  final String? audience;

  late final DidDocument didDocument;

  final browserKey = Ed25519DidKeySigner.generate();
  String matchNumber = '47';
  String? refuseWith;
  Map<String, dynamic>? receivedGrant;
  int cancels = 0;

  Future<(int, Object?)> handle(Map<String, dynamic> request) async {
    if (refuseWith case final code?) {
      return (
        400,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': vtcDid,
          'payload': {'code': code},
        },
      );
    }

    final type = request['type'] as String;
    final payload = request['payload'] as Map<String, dynamic>;
    final ext = audience == null
        ? null
        : {
            'org.openvtc.session': {'audience': audience},
          };
    final step1 = {
      'requestId': request['parentThreadId'],
      'service': {'did': vtcDid, 'name': vtcDid},
      'purpose': 'login',
      'origin': vtcOrigin,
      'decisionDeadline': fakeNow + 120,
      'ext': ?ext,
    };

    final Map<String, dynamic> answerPayload;
    if (type == OobTask.claim) {
      answerPayload = step1;
    } else if (type == OobTask.prove) {
      final identify = payload['identify'] as Map<String, dynamic>;
      final identifyPayload = identify['payload'] as Map<String, dynamic>;
      if (identifyPayload['enteredNumber'] != matchNumber) {
        refuseWith = 'auth/oob/prove:numberMismatch';
        return handle(request);
      }
      answerPayload = {
        ...step1,
        'sessionKey': browserKey.did,
        'identifiedAs': identify['issuer'],
        'requester': {
          'browser': 'Chrome',
          'os': 'macOS',
          'location': 'Berlin, DE',
          'sameNetwork': true,
          'createdAt': '2026-10-08T12:00:00Z',
        },
      };
    } else if (type == OobTask.respond) {
      receivedGrant = payload['grant'] as Map<String, dynamic>;
      answerPayload = {'status': 'approved'};
    } else if (type == OobTask.cancel) {
      cancels++;
      answerPayload = {'status': 'cancelled'};
    } else {
      throw StateError('unexpected task');
    }

    final answer = await TrustTaskDocument.create(
      type: '$type#response',
      issuer: vtcDid,
      recipient: request['issuer'] as String,
      threadId: request['id'] as String,
      payload: answerPayload,
    ).sign(_signer, purpose: ProofPurpose.assertionMethod);
    return (200, answer.toJson());
  }
}

/// A member's VTA that signs as one `did:key` persona.
class FakeSignInAgent implements SignInAgent {
  final persona = Ed25519DidKeySigner.generate();
  final List<Map<String, dynamic>?> receivedExt = [];
  String? refuseWith;
  bool signGrantForAuthentication = false;
  bool tamper = false;

  SignInPersona get signInPersona =>
      SignInPersona(did: persona.did, entryId: 'entry-1');

  @override
  String get vtaDid => 'did:web:vta.example';

  @override
  Future<Map<String, dynamic>> signTrustTask({
    required String entryId,
    required Map<String, dynamic> unsignedEnvelope,
    Map<String, dynamic>? ext,
  }) async {
    if (refuseWith case final code?) {
      throw MeetingPlaceVtcSDKException.refused(code);
    }
    receivedExt.add(ext);
    final isGrant = unsignedEnvelope['type'] == OobTask.grant;
    final purpose = isGrant && !signGrantForAuthentication
        ? ProofPurpose.assertionMethod
        : ProofPurpose.authentication;
    final signed = await EddsaJcs2022.sign(
      unsignedEnvelope,
      signer: persona,
      purpose: purpose,
    );
    if (tamper) {
      signed['payload'] = {...signed['payload'] as Map, 'extra': true};
    }
    return signed;
  }
}

/// A biometric approval key that can be made to fail.
class FakeUserVerification implements TrustTaskSigner {
  final _key = Ed25519DidKeySigner.generate();
  UserVerificationError? failWith;

  @override
  String get did => _key.did;

  @override
  String get verificationMethod => _key.verificationMethod;

  @override
  Future<Uint8List> sign(Uint8List data) async {
    if (failWith case final error?) throw UserVerificationException(error);
    return _key.sign(data);
  }
}
