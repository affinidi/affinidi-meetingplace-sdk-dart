import 'dart:typed_data';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

const _phrase = 'my-club';

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
  final now = DateTime.now().toUtc();
  final resolver = FakeDidResolver();
  late FakeSignInAgent admin;

  Future<Map<String, dynamic>> roleCard({
    required String holder,
    Ed25519DidKeySigner? issuer,
    String role = 'admin',
  }) {
    final signer = issuer ?? community;
    return EddsaJcs2022.sign(
      {
        'type': [
          'VerifiableCredential',
          'DTGCredential',
          'AuthorityCredential',
        ],
        'issuer': signer.did,
        'validFrom': formatTrustTaskTime(now.subtract(const Duration(days: 1))),
        'validUntil': formatTrustTaskTime(now.add(const Duration(days: 30))),
        'credentialSubject': {
          'id': holder,
          'authority': {
            'scope': signer.did,
            'actions': ['role:$role'],
            'maxAttenuation': 0,
          },
        },
      },
      signer: signer,
      purpose: ProofPurpose.assertionMethod,
    );
  }

  Future<Map<String, dynamic>> sign({
    Map<String, dynamic>? card,
    String phrase = _phrase,
  }) async => CommunityOffer.sign(
    agent: admin,
    persona: admin.vtaPersona,
    communityDid: community.did,
    phrase: phrase,
    roleCard: card ?? await roleCard(holder: admin.persona.did),
    resolver: resolver,
  );

  Future<String> verify(
    Map<String, dynamic> statement, {
    String phrase = _phrase,
    DateTime? at,
  }) => CommunityOffer.verify(
    statement,
    phrase: phrase,
    resolver: resolver,
    now: at ?? now,
  );

  setUp(() => admin = FakeSignInAgent());

  group('CommunityOffer.sign', () {
    test('signs as the persona, for the role card\'s lifetime', () async {
      final card = await roleCard(holder: admin.persona.did);

      final statement = await sign(card: card);

      expect(statement['type'], CommunityOffer.statementType);
      expect(statement['issuer'], admin.persona.did);
      expect(statement['communityDid'], community.did);
      expect(statement['phrase'], _phrase);
      expect(statement['validUntil'], card['validUntil']);
      expect(statement['roleCard'], card);
    });

    test('refuses to sign without an admin role card', () async {
      final member = await roleCard(holder: admin.persona.did, role: 'member');

      await expectLater(
        sign(card: member),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a role card without validUntil', () async {
      final card = await roleCard(holder: admin.persona.did)
        ..remove('validUntil');

      await expectLater(
        sign(card: card),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });
  });

  group('CommunityOffer.verify', () {
    test('returns the community a valid statement vouches for', () async {
      expect(await verify(await sign()), community.did);
    });

    test('refuses the statement under another phrase', () async {
      await expectLater(
        verify(await sign(), phrase: 'my-club-2'),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a statement whose phrase was changed', () async {
      final copied = {...await sign(), 'phrase': 'my-club-2'};

      await expectLater(
        verify(copied, phrase: 'my-club-2'),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a statement pointed at another community', () async {
      final redirected = {...await sign(), 'communityDid': other.did};

      await expectLater(
        verify(redirected),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses an admin\'s card in someone else\'s statement', () async {
      final adminCard = await roleCard(holder: admin.persona.did);
      final attacker = FakeSignInAgent();
      final statement = await EddsaJcs2022.sign(
        {
          'type': CommunityOffer.statementType,
          'issuer': attacker.persona.did,
          'communityDid': community.did,
          'phrase': _phrase,
          'validUntil': adminCard['validUntil'],
          'roleCard': adminCard,
        },
        signer: attacker.persona,
        purpose: ProofPurpose.assertionMethod,
      );

      await expectLater(
        verify(statement),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a role card another community issued', () async {
      final foreign = await roleCard(holder: admin.persona.did, issuer: other);
      final statement = await EddsaJcs2022.sign(
        {
          'type': CommunityOffer.statementType,
          'issuer': admin.persona.did,
          'communityDid': community.did,
          'phrase': _phrase,
          'validUntil': foreign['validUntil'],
          'roleCard': foreign,
        },
        signer: admin.persona,
        purpose: ProofPurpose.assertionMethod,
      );

      await expectLater(
        verify(statement),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses an expired statement', () async {
      await expectLater(
        verify(await sign(), at: now.add(const Duration(days: 31))),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a document that is not a statement', () async {
      await expectLater(
        verify({'type': 'Something', 'phrase': _phrase}),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses an unsigned statement', () async {
      final unsigned = await sign()
        ..remove('proof');

      await expectLater(
        verify(unsigned),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });
  });
}
