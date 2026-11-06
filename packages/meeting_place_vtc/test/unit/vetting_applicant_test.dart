import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';
import '../utils/fake_status_list.dart';

/// Keeps what would go to the vetter.
class _FakeMessenger implements PersonaMessenger {
  final List<TrustTaskDocument> sent = [];

  @override
  Future<void> send(TrustTaskDocument document) async => sent.add(document);
}

/// Resolves `did:key`s offline, and the persona's `did:peer`.
class _Resolver implements DidResolver {
  _Resolver(this.persona);

  final FakePersona persona;

  @override
  Future<DidDocument> resolveDid(String did) async =>
      did == persona.did ? persona.document : DidKey.resolve(did);
}

Matcher _failsWith(VettingFailure failure) => throwsA(
  isA<VettingException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  final now = DateTime.utc(2026, 11, 5, 10);
  late Ed25519DidKeySigner community;
  late Ed25519DidKeySigner vetter;
  late FakePersona persona;
  late _FakeMessenger messenger;
  late FakeStatusList statusList;
  late VettingApplicant applicant;

  VettingTicket ticket({String? communityDid}) => VettingTicket.spoken(
    community: communityDid ?? community.did,
    vetter: vetter.did,
    code: 'K7QF-2M9X',
  )!;

  Future<Map<String, dynamic>> roleCard({
    String role = 'vetter',
    Ed25519DidKeySigner? issuer,
    String validUntil = '2027-11-01T00:00:00Z',
    String issuerScope = 'public',
  }) => EddsaJcs2022.sign(
    {
      'type': ['VerifiableCredential', 'DTGCredential', 'AuthorityCredential'],
      'issuer': (issuer ?? community).did,
      'issuerScope': issuerScope,
      'validFrom': '2026-01-01T00:00:00Z',
      'validUntil': validUntil,
      'credentialSubject': {
        'id': vetter.did,
        'authority': {
          'scope': community.did,
          'actions': ['role:$role'],
        },
      },
    },
    signer: issuer ?? community,
    purpose: ProofPurpose.assertionMethod,
  );

  Future<TrustTaskDocument> fromVetter(
    String type,
    Map<String, dynamic> payload, {
    String? threadId,
  }) => TrustTaskDocument.create(
    type: type,
    issuer: vetter.did,
    recipient: persona.did,
    threadId: threadId,
    payload: payload,
  ).sign(vetter, purpose: ProofPurpose.authentication);

  Future<TrustTaskDocument> acceptance(
    TrustTaskDocument request, {
    Map<String, dynamic>? card,
    String? nonce,
    bool withPresentation = true,
  }) async => fromVetter(VettingTask.requestResponse, {
    'requestId': 'vr-1',
    if (withPresentation)
      'eligibilityVp': await EddsaJcs2022.sign(
        {
          '@context': ['https://www.w3.org/ns/credentials/v2'],
          'type': ['VerifiablePresentation'],
          'holder': vetter.did,
          'nonce': nonce ?? request.id,
          'domain': persona.did,
          'verifiableCredential': [card ?? await roleCard()],
        },
        signer: vetter,
        purpose: ProofPurpose.authentication,
      ),
  }, threadId: request.id);

  Future<AcceptedVetter> accept(
    TrustTaskDocument request,
    TrustTaskDocument answer,
  ) => applicant.accepted(
    answer,
    request: request,
    communityDid: community.did,
    vetterRole: 'vetter',
  );

  setUp(() async {
    community = Ed25519DidKeySigner.generate();
    vetter = Ed25519DidKeySigner.generate();
    persona = FakePersona();
    messenger = _FakeMessenger();
    statusList = FakeStatusList();
    applicant = VettingApplicant(
      persona: await PersonaDidManager.borrow(
        document: persona.document,
        signingSeed: persona.signingSeed,
        keyAgreementKey: persona.keyAgreementKey,
      ),
      messenger: messenger,
      didResolver: _Resolver(persona),
      statusList: statusList,
      now: () => now,
    );
  });

  group('request', () {
    test('asks the vetter as the persona, with the ticket', () async {
      final request = await applicant.request(
        communityDid: community.did,
        ticket: ticket(),
        requirementsDigest: 'zDigest',
      );

      expect(messenger.sent.single.toJson(), request.toJson());
      expect(request.type, VettingTask.request);
      expect(request.issuer, persona.did);
      expect(request.recipient, vetter.did);
      expect(request.payload, {
        'community': community.did,
        'joinDid': persona.did,
        'ticket': {'code': 'K7QF-2M9X'},
        'requirementsDigest': 'zDigest',
      });
      await EddsaJcs2022.verify(
        request.toJson(),
        purpose: ProofPurpose.authentication,
        resolver: _Resolver(persona),
        expectedSigner: persona.did,
      );
    });

    test('refuses a ticket of another community, sending nothing', () {
      expect(
        applicant.request(
          communityDid: community.did,
          ticket: ticket(communityDid: 'did:key:other'),
        ),
        _failsWith(VettingFailure.otherCommunity),
      );
      expect(messenger.sent, isEmpty);
    });
  });

  group('accepted', () {
    late TrustTaskDocument request;

    setUp(() async {
      request = await applicant.request(
        communityDid: community.did,
        ticket: ticket(),
      );
    });

    test('takes a vetter who shows the community granted the role', () async {
      final vetterAccepted = await accept(request, await acceptance(request));

      expect(vetterAccepted.vetterDid, vetter.did);
      expect(vetterAccepted.requestId, 'vr-1');
      expect(vetterAccepted.roleValidUntil, DateTime.utc(2027, 11));
      expect(statusList.checked, hasLength(1));
    });

    test('says why the vetter refused', () async {
      final refusal = await fromVetter(
        'https://trusttasks.org/spec/trust-task-error/0.5',
        {'code': 'vetting/request:invalidTicket'},
        threadId: request.id,
      );

      expect(
        accept(request, refusal),
        _failsWith(VettingFailure.invalidTicket),
      );
    });

    test('refuses a vetter whose role the community withdrew', () async {
      statusList.state = CredentialStatusState.revoked;

      expect(
        accept(request, await acceptance(request)),
        _failsWith(VettingFailure.vetterRevoked),
      );
    });

    test('refuses a vetter who cannot show the role', () async {
      final other = Ed25519DidKeySigner.generate();
      for (final answer in [
        await acceptance(request, withPresentation: false),
        await acceptance(request, nonce: 'urn:uuid:another-request'),
        await acceptance(request, card: await roleCard(role: 'admin')),
        await acceptance(request, card: await roleCard(issuer: other)),
        await acceptance(
          request,
          card: await roleCard(issuerScope: 'directed'),
        ),
        await acceptance(
          request,
          card: await roleCard(validUntil: '2026-11-01T00:00:00Z'),
        ),
      ]) {
        await expectLater(
          accept(request, answer),
          _failsWith(VettingFailure.notVetter),
        );
      }
    });

    test('refuses a role card the community did not sign', () async {
      final card = await roleCard();
      (card['credentialSubject'] as Map)['id'] = vetter.did;
      card['validUntil'] = '2027-12-01T00:00:00Z';

      expect(
        accept(request, await acceptance(request, card: card)),
        _failsWith(VettingFailure.badAnswer),
      );
    });

    test('refuses an answer to another request', () async {
      final answer = await fromVetter(VettingTask.requestResponse, {
        'requestId': 'vr-1',
      }, threadId: 'urn:uuid:another-request');

      expect(accept(request, answer), _failsWith(VettingFailure.badAnswer));
    });
  });

  group('a session', () {
    late AcceptedVetter accepted;

    Future<TrustTaskDocument> session({
      String requestId = 'vr-1',
      String expiresAt = '2026-11-05T10:15:00Z',
      String? domain,
    }) => fromVetter(VettingTask.session, {
      'requestId': requestId,
      'challenge': 'QlScnBiVZptGM8oLBRk4S37fjuDCr381MUrrnd0cmHg',
      'domain': domain ?? community.did,
      'method': 'inPerson',
      'requiredClaims': ['name.legal'],
      'optionalClaims': ['address.locality'],
      'expiresAt': expiresAt,
    });

    setUp(() {
      accepted = AcceptedVetter(
        vetterDid: vetter.did,
        requestId: 'vr-1',
        roleValidUntil: DateTime.utc(2027),
      );
    });

    test('opens one for the accepted request', () async {
      final document = await session();

      final opened = applicant.openSession(
        document,
        vetter: accepted,
        communityDid: community.did,
      );

      expect(opened.method, VettingMethod.inPerson);
      expect(opened.requiredClaims, ['name.legal']);
      expect(opened.optionalClaims, ['address.locality']);
      expect(opened.matchCode, vettingMatchCode(document.id));
    });

    test('refuses a lapsed or foreign session', () async {
      for (final (document, failure) in [
        (
          await session(expiresAt: '2026-11-05T09:59:00Z'),
          VettingFailure.sessionExpired,
        ),
        (await session(requestId: 'vr-2'), VettingFailure.badAnswer),
        (await session(domain: 'did:key:other'), VettingFailure.badAnswer),
      ]) {
        expect(
          () => applicant.openSession(
            document,
            vetter: accepted,
            communityDid: community.did,
          ),
          _failsWith(failure),
        );
      }
    });

    group('then', () {
      late VettingSession opened;
      late SentCard sent;
      const claims = [VettingCardClaim(type: 'name.legal', value: 'Ada')];

      Future<TrustTaskDocument> statementIssue({
        String? subject,
        String? cardDigest,
        String validUntil = '2027-11-05T10:00:00Z',
      }) async {
        final statement = await EddsaJcs2022.sign(
          {
            '@context': ['https://www.w3.org/ns/credentials/v2'],
            'type': [
              'VerifiableCredential',
              'DTGCredential',
              'StatementCredential',
            ],
            'id': 'urn:uuid:statement',
            'issuer': vetter.did,
            'issuerScope': 'directed',
            'validFrom': '2026-11-05T10:00:00Z',
            'validUntil': validUntil,
            'taskContext': opened.document.id,
            'taskDigestMultibase': vettingDigest(opened.document.toJson()),
            'credentialSubject': {
              'id': subject ?? persona.did,
              'predicate': VettingStatement.predicate,
              'object': {
                'value': {
                  'community': community.did,
                  'method': 'inPerson',
                  'documentClasses': ['passport'],
                  'claimsVerified': ['name.legal'],
                  'livenessConfirmed': true,
                  'identityCommitment': sent.identityCommitment,
                  'cardDigestMultibase': cardDigest ?? sent.cardDigest,
                  'declaredRelationship': 'none',
                },
              },
            },
          },
          signer: vetter,
          purpose: ProofPurpose.assertionMethod,
        );
        return fromVetter(VettingTask.issue, {
          'credential_response': {'credential': statement},
        }, threadId: opened.document.id);
      }

      setUp(() async {
        opened = applicant.openSession(
          await session(),
          vetter: accepted,
          communityDid: community.did,
        );
        sent = await applicant.sendCard(
          opened,
          claims: claims,
          salt: 'salt-1',
          parentThreadId: 'urn:uuid:request',
        );
      });

      test('sends a card bound to the session, signed as the persona', () {
        final answer = messenger.sent.single;
        expect(answer.type, VettingTask.sessionResponse);
        expect(answer.recipient, vetter.did);
        expect(answer.threadId, opened.document.id);
        expect(answer.parentThreadId, 'urn:uuid:request');
        final card = answer.payload['card'] as Map<String, dynamic>;
        expect(card['publisher'], persona.did);
        expect(card['audience'], vetter.did);
        expect(card['challenge'], opened.document.payload['challenge']);
        expect(card['claims'], [
          {'type': 'name.legal', 'value': 'Ada', 'provenance': 'selfAsserted'},
        ]);
        expect(card['expiresAt'], '2026-11-05T10:15:00.000Z');
        expect((card['proof'] as Map)['proofPurpose'], 'assertionMethod');
        expect(sent.cardDigest, vettingDigest(card));
        expect(
          sent.identityCommitment,
          vettingIdentityCommitment(
            salt: 'salt-1',
            claims: claims,
            identityTypes: const ['name.legal'],
          ),
        );
      });

      test('takes the statement made over that card', () async {
        final statement = await applicant.receiveStatement(
          await statementIssue(),
          session: opened,
          sent: sent,
          communityDid: community.did,
        );

        expect(statement.vetterDid, vetter.did);
        expect(statement.applicantDid, persona.did);
      });

      test('refuses a statement that is not about this session', () async {
        for (final issue in [
          await statementIssue(subject: 'did:key:someone-else'),
          await statementIssue(cardDigest: 'zAnotherCard'),
          await statementIssue(validUntil: '2026-11-05T09:00:00Z'),
        ]) {
          await expectLater(
            applicant.receiveStatement(
              issue,
              session: opened,
              sent: sent,
              communityDid: community.did,
            ),
            _failsWith(VettingFailure.badAnswer),
          );
        }
      });

      test('refuses a statement the vetter did not sign', () async {
        final issue = await statementIssue();
        final credential =
            (issue.payload['credential_response'] as Map)['credential']
                as Map<String, dynamic>;
        credential['validUntil'] = '2028-01-01T00:00:00Z';

        expect(
          applicant.receiveStatement(
            issue,
            session: opened,
            sent: sent,
            communityDid: community.did,
          ),
          _failsWith(VettingFailure.badAnswer),
        );
      });
    });

    test('ends the request, signed as the persona', () async {
      await applicant.decline(
        vetter: accepted,
        parentThreadId: 'urn:uuid:request',
        code: 'matchCodeDiffers',
      );

      final sent = messenger.sent.single;
      expect(sent.type, VettingTask.decline);
      expect(sent.issuer, applicant.joinDid);
      expect(sent.recipient, vetter.did);
      expect(sent.parentThreadId, 'urn:uuid:request');
      expect(sent.payload, {'requestId': 'vr-1', 'code': 'matchCodeDiffers'});
      expect(sent.toJson()['proof'], isNotNull);
    });

    test('reads a decline', () async {
      final decline = await fromVetter(VettingTask.decline, {
        'requestId': 'vr-1',
        'code': 'couldNotVerify',
        'message': 'Your passport had expired.',
      });

      final declined = applicant.declined(decline, vetter: accepted);

      expect(declined.code, 'couldNotVerify');
      expect(declined.message, 'Your passport had expired.');
    });
  });
}
