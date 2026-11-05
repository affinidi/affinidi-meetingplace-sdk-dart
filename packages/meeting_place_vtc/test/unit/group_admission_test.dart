import 'dart:typed_data';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

/// Answers a fixed status for every credential, or fails to read it.
class _FakeStatusList extends StatusListClient {
  _FakeStatusList();

  CredentialStatusState state = CredentialStatusState.valid;
  bool isUnreadable = false;

  @override
  Future<CredentialStatusCheck> check(Map<String, dynamic> credential) async {
    if (isUnreadable) {
      throw MeetingPlaceVtcSDKException.transportFailed('unreachable');
    }
    return CredentialStatusCheck(state: state, checkedAt: DateTime.now());
  }
}

class _DidKeyResolver implements DidResolver {
  @override
  Future<DidDocument> resolveDid(String did) async => DidKey.resolve(did);
}

Ed25519DidKeySigner _signer(int seed) =>
    Ed25519DidKeySigner.fromSeed(Uint8List.fromList(List.filled(32, seed)));

Matcher _refused(GroupAdmissionRefusal reason) => throwsA(
  isA<GroupAdmissionException>().having((e) => e.reason, 'reason', reason),
);

void main() {
  final groupKey = _signer(1);
  final community = _signer(2);
  final holder = _signer(3);
  final stranger = _signer(4);
  const memberDid = 'did:web:mpx.example:user:member';
  final now = DateTime.utc(2026, 11, 5, 10);

  late _FakeStatusList statusList;
  late GroupAdmissionVerifier verifier;

  Future<Map<String, dynamic>> membership({
    TrustTaskSigner? signer,
    String? issuer,
    String? subject,
    DateTime? validUntil,
  }) => EddsaJcs2022.sign(
    {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'id': 'urn:uuid:group-card',
      'type': ['VerifiableCredential', 'DTGCredential', 'MembershipCredential'],
      'issuer': issuer ?? groupKey.did,
      'validFrom': '2026-11-01T00:00:00Z',
      'validUntil': (validUntil ?? DateTime.utc(2026, 12, 1)).toIso8601String(),
      'credentialSubject': {'id': subject ?? holder.did},
    },
    signer: signer ?? groupKey,
    purpose: ProofPurpose.assertionMethod,
  );

  Future<Map<String, dynamic>> presentation({
    Map<String, dynamic>? credential,
    String? domain,
    String? nonce,
    TrustTaskSigner? signer,
  }) async => EddsaJcs2022.sign(
    {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'type': ['VerifiablePresentation'],
      'holder': holder.did,
      'verifiableCredential': [credential ?? await membership()],
      'nonce': nonce ?? memberDid,
      'domain': domain ?? groupKey.did,
    },
    signer: signer ?? holder,
    purpose: ProofPurpose.authentication,
  );

  Future<Map<String, dynamic>> authority({
    TrustTaskSigner? signer,
    String? issuer,
    String? scope,
    List<String> actions = const ['issue-membership'],
    DateTime? validUntil,
  }) => EddsaJcs2022.sign(
    {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'id': 'urn:uuid:group-authority',
      'type': ['VerifiableCredential', 'DTGCredential', 'AuthorityCredential'],
      'issuer': issuer ?? community.did,
      'validFrom': '2026-01-01T00:00:00Z',
      'validUntil': (validUntil ?? DateTime.utc(2027, 1, 1)).toIso8601String(),
      'credentialSubject': {
        'id': groupKey.did,
        'authority': {'scope': scope ?? community.did, 'actions': actions},
      },
    },
    signer: signer ?? community,
    purpose: ProofPurpose.assertionMethod,
  );

  Future<GroupAdmission> verify({
    Map<String, dynamic>? withPresentation,
    Map<String, dynamic>? withAuthority,
  }) async => verifier.verify(
    presentation: withPresentation ?? await presentation(),
    authority: withAuthority ?? await authority(),
    groupDid: groupKey.did,
    communityDid: community.did,
    memberDid: memberDid,
  );

  setUp(() {
    statusList = _FakeStatusList();
    verifier = GroupAdmissionVerifier(
      didResolver: _DidKeyResolver(),
      statusListClient: statusList,
      now: () => now,
    );
  });

  group('GroupAdmissionVerifier', () {
    test('admits a member of the group, naming their credential', () async {
      final admission = await verify();

      expect(admission.holderDid, holder.did);
      expect(admission.credentialId, 'urn:uuid:group-card');
      expect(admission.validUntil, DateTime.utc(2026, 12, 1));
    });

    test('refuses a presentation made for another joiner', () async {
      await expectLater(
        verify(
          withPresentation: await presentation(
            nonce: 'did:web:mpx.example:user:other',
          ),
        ),
        _refused(GroupAdmissionRefusal.notForThisRequest),
      );
    });

    test('refuses a presentation made for another chat', () async {
      await expectLater(
        verify(withPresentation: await presentation(domain: stranger.did)),
        _refused(GroupAdmissionRefusal.notForThisRequest),
      );
    });

    test('refuses a presentation its holder did not sign', () async {
      await expectLater(
        verify(withPresentation: await presentation(signer: stranger)),
        _refused(GroupAdmissionRefusal.presentationInvalid),
      );
    });

    test('refuses a membership another group issued', () async {
      await expectLater(
        verify(
          withPresentation: await presentation(
            credential: await membership(
              issuer: stranger.did,
              signer: stranger,
            ),
          ),
        ),
        _refused(GroupAdmissionRefusal.notThisGroup),
      );
    });

    test('refuses a membership not signed by the group', () async {
      await expectLater(
        verify(
          withPresentation: await presentation(
            credential: await membership(signer: stranger),
          ),
        ),
        _refused(GroupAdmissionRefusal.membershipInvalid),
      );
    });

    test('refuses a membership about someone else', () async {
      await expectLater(
        verify(
          withPresentation: await presentation(
            credential: await membership(subject: stranger.did),
          ),
        ),
        _refused(GroupAdmissionRefusal.membershipInvalid),
      );
    });

    test('refuses an expired membership', () async {
      await expectLater(
        verify(
          withPresentation: await presentation(
            credential: await membership(validUntil: DateTime.utc(2026, 11)),
          ),
        ),
        _refused(GroupAdmissionRefusal.membershipExpired),
      );
    });

    test('refuses a grant the group gave itself', () async {
      await expectLater(
        verify(
          withAuthority: await authority(
            issuer: groupKey.did,
            scope: groupKey.did,
            signer: groupKey,
          ),
        ),
        _refused(GroupAdmissionRefusal.authorityInvalid),
      );
    });

    test('refuses a grant without issue-membership', () async {
      await expectLater(
        verify(withAuthority: await authority(actions: const ['read'])),
        _refused(GroupAdmissionRefusal.authorityInvalid),
      );
    });

    test('refuses a grant not signed by the community', () async {
      await expectLater(
        verify(withAuthority: await authority(signer: stranger)),
        _refused(GroupAdmissionRefusal.authorityInvalid),
      );
    });

    test('refuses an expired grant', () async {
      await expectLater(
        verify(
          withAuthority: await authority(validUntil: DateTime.utc(2026, 6)),
        ),
        _refused(GroupAdmissionRefusal.authorityExpired),
      );
    });

    test('refuses a grant the community revoked', () async {
      statusList.state = CredentialStatusState.revoked;

      await expectLater(
        verify(),
        _refused(GroupAdmissionRefusal.authorityRevoked),
      );
    });

    test('refuses when the grant cannot be checked', () async {
      statusList.isUnreadable = true;

      await expectLater(
        verify(),
        _refused(GroupAdmissionRefusal.authorityStatusUnknown),
      );
    });
  });
}
