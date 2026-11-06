import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

/// Resolves `did:key`s offline.
class _DidKeyResolver implements DidResolver {
  @override
  Future<DidDocument> resolveDid(String did) async => DidKey.resolve(did);
}

Matcher _refused(VettingCardRefusal refusal) => throwsA(
  isA<VettingCardException>().having((e) => e.refusal, 'refusal', refusal),
);

void main() {
  final resolver = _DidKeyResolver();
  const community = 'did:webvh:QmCommunity:dids.example:community';
  const challenge = 'QlScnBiVZptGM8oLBRk4S37fjuDCr381MUrrnd0cmHg';
  final issuedAt = DateTime.utc(2026, 11, 6, 9);
  late Ed25519DidKeySigner applicant;
  late Ed25519DidKeySigner vetter;

  setUp(() {
    applicant = Ed25519DidKeySigner.generate();
    vetter = Ed25519DidKeySigner.generate();
  });

  Future<Map<String, dynamic>> card({
    Map<String, dynamic> Function(Map<String, dynamic>)? change,
    Duration validity = const Duration(minutes: 15),
    List<String> identityTypes = const ['name.legal'],
  }) {
    final unsigned = unsignedVettingCard(
      id: 'urn:uuid:card-1',
      publisher: applicant.did,
      audience: vetter.did,
      community: community,
      challenge: challenge,
      domain: community,
      issuedAt: issuedAt,
      validity: validity,
      claims: const [
        VettingCardClaim(type: 'name.legal', value: 'Ada Lovelace'),
        VettingCardClaim(type: 'address.country', value: 'GB'),
      ],
      identityTypes: identityTypes,
      salt: 'salt-1',
    );
    return EddsaJcs2022.sign(
      change?.call(unsigned) ?? unsigned,
      signer: applicant,
      purpose: ProofPurpose.assertionMethod,
    );
  }

  Future<List<VettingCardClaim>> verify(
    Map<String, dynamic> card, {
    DateTime? now,
    DateTime? sessionExpiresAt,
    List<String> requiredClaims = const ['name.legal'],
  }) => verifyVettingCard(
    card,
    applicantDid: applicant.did,
    vetterDid: vetter.did,
    communityDid: community,
    challenge: challenge,
    sessionExpiresAt:
        sessionExpiresAt ?? issuedAt.add(const Duration(minutes: 15)),
    requiredClaims: requiredClaims,
    didResolver: resolver,
    now: now ?? issuedAt.add(const Duration(minutes: 1)),
  );

  group('verifyVettingCard', () {
    test(
      'returns the required claims of a card bound to the session',
      () async {
        final claims = await verify(await card());

        expect(claims.map((claim) => (claim.type, claim.value)), [
          ('name.legal', 'Ada Lovelace'),
        ]);
      },
    );

    test('accepts the card upstream signed', () async {
      final vectors =
          jsonDecode(
                File(
                  'test/fixtures/vetting_conformance_vectors.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final upstream =
          (vectors['cardDigest'] as Map<String, dynamic>)['card']
              as Map<String, dynamic>;
      final issued = DateTime.parse(upstream['issuedAt'] as String);

      final claims = await verifyVettingCard(
        upstream,
        applicantDid: upstream['publisher'] as String,
        vetterDid: upstream['audience'] as String,
        communityDid: upstream['community'] as String,
        challenge: upstream['challenge'] as String,
        sessionExpiresAt: DateTime.parse(upstream['expiresAt'] as String),
        requiredClaims: const ['name.legal'],
        didResolver: resolver,
        now: issued,
      );

      expect(claims.single.value, 'Ada Lovelace');
    });

    test('refuses a card made for another session or vetter', () async {
      for (final member in [
        'publisher',
        'audience',
        'community',
        'domain',
        'challenge',
      ]) {
        final other = await card(
          change: (card) => {...card, member: 'did:key:z6MkOther'},
        );
        await expectLater(
          verify(other),
          _refused(VettingCardRefusal.binding),
          reason: member,
        );
      }
    });

    test('refuses a card that is not a vetting card', () async {
      final notCard = await card(
        change: (card) => {
          ...card,
          'type': ['VerifiableDataStructure'],
        },
      );

      await expectLater(verify(notCard), _refused(VettingCardRefusal.shape));
    });

    test('refuses a card out of date or outliving the session', () async {
      final made = await card();

      await expectLater(
        verify(made, now: issuedAt.add(const Duration(minutes: 17))),
        _refused(VettingCardRefusal.expired),
      );
      await expectLater(
        verify(made, now: issuedAt.subtract(const Duration(minutes: 2))),
        _refused(VettingCardRefusal.expired),
      );
      await expectLater(
        verify(
          made,
          sessionExpiresAt: issuedAt.add(const Duration(minutes: 10)),
        ),
        _refused(VettingCardRefusal.expired),
      );
    });

    test('refuses a card changed after it was signed', () async {
      final changed = {...await card(), 'cardVersion': 1, 'id': 'urn:uuid:x'};

      await expectLater(verify(changed), _refused(VettingCardRefusal.proof));
    });

    test('refuses a card without a required claim', () async {
      await expectLater(
        verify(
          await card(),
          requiredClaims: ['name.legal', 'person.birthDate'],
        ),
        _refused(VettingCardRefusal.missingClaim),
      );
    });

    test('refuses a commitment to other claims', () async {
      final madeForCountry = await card(identityTypes: ['address.country']);

      await expectLater(
        verify(madeForCountry),
        _refused(VettingCardRefusal.commitment),
      );
    });
  });

  test(
    'vetterEligibilityPresentation shows the role card, as the vetter',
    () async {
      final vp = await vetterEligibilityPresentation(
        roleCard: {
          'type': ['AuthorityCredential'],
        },
        nonce: 'urn:uuid:request-1',
        domain: applicant.did,
        signer: vetter,
      );

      expect(vp['holder'], vetter.did);
      expect(vp['nonce'], 'urn:uuid:request-1');
      expect(vp['domain'], applicant.did);
      expect(vp['verifiableCredential'], [
        {
          'type': ['AuthorityCredential'],
        },
      ]);
      await EddsaJcs2022.verify(
        vp,
        purpose: ProofPurpose.authentication,
        resolver: resolver,
        expectedSigner: vetter.did,
      );
    },
  );
}
