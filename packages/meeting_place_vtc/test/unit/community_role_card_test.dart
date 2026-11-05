import 'dart:typed_data';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';

const _persona = 'did:webvh:persona';

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

void main() {
  final community = Ed25519DidKeySigner.fromSeed(
    Uint8List.fromList(List.filled(32, 7)),
  );
  final other = Ed25519DidKeySigner.fromSeed(
    Uint8List.fromList(List.filled(32, 9)),
  );
  final now = DateTime.utc(2026, 11, 5, 10);
  final resolver = FakeDidResolver();

  Future<Map<String, dynamic>> card({
    Ed25519DidKeySigner? signer,
    String? issuer,
    String holder = _persona,
    String? scope,
    List<String> actions = const ['role:admin'],
    String? validFrom = '2026-11-01T10:00:00Z',
    String? validUntil = '2026-12-01T10:00:00Z',
    List<String> types = const [
      'VerifiableCredential',
      'DTGCredential',
      'AuthorityCredential',
    ],
  }) => EddsaJcs2022.sign(
    {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'id': 'urn:uuid:role',
      'type': types,
      'issuer': issuer ?? community.did,
      'issuerScope': 'public',
      'validFrom': ?validFrom,
      'validUntil': ?validUntil,
      'credentialSubject': {
        'id': holder,
        'authority': {
          'scope': scope ?? community.did,
          'actions': actions,
          'maxAttenuation': 0,
        },
      },
    },
    signer: signer ?? community,
    purpose: ProofPurpose.assertionMethod,
  );

  Future<void> verify(Map<String, dynamic> card, {String role = 'admin'}) =>
      CommunityRoleCard.verify(
        card,
        communityDid: community.did,
        holderDid: _persona,
        role: role,
        resolver: resolver,
        now: now,
      );

  group('CommunityRoleCard.verify', () {
    test('accepts the community\'s grant of the role to the holder', () async {
      await expectLater(verify(await card()), completes);
    });

    test('refuses a card that is not a role card', () async {
      final membership = await card(
        types: ['VerifiableCredential', 'MembershipCredential'],
      );

      await expectLater(
        verify(membership),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a card another community issued', () async {
      final foreign = await card(signer: other, issuer: other.did);

      await expectLater(
        verify(foreign),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a card made out to someone else', () async {
      await expectLater(
        verify(await card(holder: 'did:webvh:someone-else')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a grant scoped to another community', () async {
      await expectLater(
        verify(await card(scope: other.did)),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a card of another role', () async {
      await expectLater(
        verify(await card(actions: ['role:member'])),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses an expired card', () async {
      await expectLater(
        verify(await card(validUntil: '2026-11-05T09:00:00Z')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a card not valid yet', () async {
      await expectLater(
        verify(await card(validFrom: '2026-11-05T11:00:00Z')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a card without validUntil', () async {
      await expectLater(
        verify(await card(validUntil: null)),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('tolerates the clock skew at the end of the validity', () async {
      final justExpired = await card(validUntil: '2026-11-05T09:58:00Z');

      await expectLater(verify(justExpired), completes);
    });

    test('refuses a card the community did not sign', () async {
      final forged = await card(signer: other);

      await expectLater(
        verify(forged),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a card whose role was changed after signing', () async {
      final member = await card(actions: ['role:member']);
      final promoted = {
        ...member,
        'credentialSubject': {
          'id': _persona,
          'authority': {
            'scope': community.did,
            'actions': ['role:admin'],
            'maxAttenuation': 0,
          },
        },
      };

      await expectLater(
        verify(promoted),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });
  });

  test('CommunityRoleCard.grants reads the role a card grants', () async {
    final admin = await card();

    bool grants({String holder = _persona, String role = 'admin'}) =>
        CommunityRoleCard.grants(
          admin,
          communityDid: community.did,
          holderDid: holder,
          role: role,
        );

    expect(grants(), isTrue);
    expect(grants(role: 'member'), isFalse);
    expect(grants(holder: 'did:webvh:someone-else'), isFalse);
  });

  test('CommunityRoleCard.validUntil reads the end of the validity', () async {
    expect(
      CommunityRoleCard.validUntil(await card()),
      DateTime.utc(2026, 12, 1, 10),
    );
  });
}
