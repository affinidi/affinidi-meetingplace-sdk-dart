import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

const _claimType = 'https://trusttasks.org/spec/auth/oob/claim/0.1';
const _vtcDid = 'did:webvh:QmScid:community.example';

void main() {
  final resolver = UniversalDIDResolver.defaultResolver;

  group('TrustTaskDocument', () {
    test('builds the Trust Task envelope', () {
      final document = TrustTaskDocument.create(
        type: _claimType,
        issuer: 'did:key:z6MkIssuer',
        recipient: _vtcDid,
        parentThreadId: 'request-1',
        payload: {'requestId': 'request-1'},
        issuedAt: DateTime.utc(2026, 10, 11, 7, 33, 0, 123),
      );

      final json = document.toJson();
      expect(json['id'], startsWith('urn:uuid:'));
      expect(json['issuedAt'], '2026-10-11T07:33:00Z');
      expect(json['parentThreadId'], 'request-1');
      expect(json.containsKey('threadId'), isFalse);
      expect(json.containsKey('ext'), isFalse);
      expect(document.isSigned, isFalse);
    });

    test('signs as its issuer and verifies', () async {
      final signer = Ed25519DidKeySigner.generate();
      final document = await TrustTaskDocument.create(
        type: _claimType,
        issuer: signer.did,
        recipient: _vtcDid,
        payload: {'requestId': 'request-1'},
      ).sign(signer, purpose: ProofPurpose.authentication);

      expect(document.isSigned, isTrue);
      await expectLater(
        document.verify(
          purpose: ProofPurpose.authentication,
          resolver: resolver,
        ),
        completes,
      );
    });

    test('refuses to sign for a different issuer', () {
      final document = TrustTaskDocument.create(
        type: _claimType,
        issuer: 'did:key:z6MkSomeoneElse',
        recipient: _vtcDid,
        payload: const {},
      );

      expect(
        document.sign(
          Ed25519DidKeySigner.generate(),
          purpose: ProofPurpose.authentication,
        ),
        throwsA(isA<MeetingPlaceVtcSDKException>()),
      );
    });

    test('keeps unknown members of a received document', () {
      final document = TrustTaskDocument.fromJson({
        'id': 'urn:uuid:1',
        'type': '$_claimType#response',
        'issuer': _vtcDid,
        'payload': <String, dynamic>{},
        'futureMember': 'kept',
      });

      expect(document.toJson()['futureMember'], 'kept');
    });

    test('rejects a received document without a payload', () {
      expect(
        () => TrustTaskDocument.fromJson({
          'id': 'urn:uuid:1',
          'type': _claimType,
          'issuer': _vtcDid,
        }),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (error) => error.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.invalidDocument,
          ),
        ),
      );
    });
  });

  group('digestMultibase', () {
    test('hashes the JCS form as a SHA2-256 multihash', () {
      final digest = digestMultibase({
        'b': [1, 'x'],
        'a': {'z': true, 'y': null},
      });

      expect(digest, 'zQmUMHcvoQk3tc3fGsvskdS1Xq58tqxmLy98QSXyUvpQmin');
    });

    test('ignores member order', () {
      expect(
        digestMultibase({'a': 1, 'b': 2}),
        digestMultibase({'b': 2, 'a': 1}),
      );
    });
  });
}
