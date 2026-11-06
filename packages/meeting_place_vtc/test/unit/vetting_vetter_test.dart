import 'dart:convert';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';
import '../utils/fake_status_list.dart';

/// Keeps what would be sent.
class _FakeMessenger implements PersonaMessenger {
  final List<TrustTaskDocument> sent = [];

  @override
  Future<void> send(TrustTaskDocument document) async => sent.add(document);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Signs as the vetter's persona, as its VTA would, and keeps app state.
class _FakeVta implements VtaClient {
  _FakeVta(this.keys);

  final PersonaDidManager keys;
  final Map<String, Object?> records = {};
  final List<Map<String, dynamic>> signed = [];

  @override
  Future<Map<String, dynamic>> signDocument({
    required String keyId,
    required Map<String, dynamic> document,
    required String purpose,
  }) async {
    signed.add(document);
    return EddsaJcs2022.sign(
      document,
      signer: keys.signer,
      purpose: ProofPurpose.assertionMethod,
    );
  }

  @override
  Future<int> putAppState({
    required String contextId,
    required String namespace,
    required String key,
    required Object? value,
    int? expectedVersion,
  }) async {
    records['$contextId/$namespace/$key'] = value;
    return records.length;
  }

  @override
  Future<List<AppStateRecord>> listAppState({
    required String contextId,
    required String namespace,
    String? prefix,
  }) async => [
    for (final MapEntry(:key, :value) in records.entries)
      if (key.startsWith('$contextId/$namespace/${prefix ?? ''}'))
        AppStateRecord(key: key, version: 1, value: value),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Resolves the two personas' `did:peer`s and `did:key`s offline.
class _Resolver implements DidResolver {
  _Resolver(this.personas);

  final List<FakePersona> personas;

  @override
  Future<DidDocument> resolveDid(String did) async =>
      personas.where((persona) => persona.did == did).firstOrNull?.document ??
      DidKey.resolve(did);
}

void main() {
  final now = DateTime.utc(2026, 11, 6, 9);
  late Ed25519DidKeySigner community;
  late FakePersona vetterPersona;
  late FakePersona applicantPersona;
  late PersonaDidManager applicantKeys;
  late _FakeMessenger toApplicant;
  late _FakeMessenger toVetter;
  late _FakeVta vta;
  late FakeStatusList statusList;
  late VettingVetter vetter;
  late VettingApplicant applicant;
  late VetterTicket ticket;
  late Map<String, dynamic> roleCard;

  Future<PersonaDidManager> keysOf(FakePersona persona) =>
      PersonaDidManager.borrow(
        document: persona.document,
        signingSeed: persona.signingSeed,
        keyAgreementKey: persona.keyAgreementKey,
      );

  setUp(() async {
    community = Ed25519DidKeySigner.generate();
    vetterPersona = FakePersona();
    applicantPersona = FakePersona();
    final vetterKeys = await keysOf(vetterPersona);
    applicantKeys = await keysOf(applicantPersona);
    final resolver = _Resolver([vetterPersona, applicantPersona]);
    toApplicant = _FakeMessenger();
    toVetter = _FakeMessenger();
    vta = _FakeVta(vetterKeys);
    statusList = FakeStatusList()..state = CredentialStatusState.valid;
    vetter = VettingVetter(
      communityDid: community.did,
      persona: VtaPersona(did: vetterPersona.did, contextId: 'ctx'),
      personaKeys: vetterKeys,
      messenger: toApplicant,
      vta: vta,
      didResolver: resolver,
      now: () => now,
    );
    applicant = VettingApplicant(
      persona: applicantKeys,
      messenger: toVetter,
      didResolver: resolver,
      statusList: statusList,
      now: () => now,
    );
    ticket = VetterTicket.mint(
      community: community.did,
      vetter: vetterPersona.did,
      now: now,
    );
    roleCard = await EddsaJcs2022.sign(
      {
        'type': [
          'VerifiableCredential',
          'DTGCredential',
          'AuthorityCredential',
        ],
        'issuer': community.did,
        'issuerScope': 'public',
        'validFrom': '2026-01-01T00:00:00Z',
        'validUntil': '2027-11-01T00:00:00Z',
        'credentialSubject': {
          'id': vetterPersona.did,
          'authority': {
            'scope': community.did,
            'actions': ['role:vetter'],
          },
        },
      },
      signer: community,
      purpose: ProofPurpose.assertionMethod,
    );
  });

  Future<TrustTaskDocument> request(VettingTicket shown) =>
      applicant.request(communityDid: community.did, ticket: shown);

  Future<TakenRequest?> take(
    TrustTaskDocument request, {
    List<VetterTicket>? tickets,
    bool holdsRole = true,
  }) => vetter.takeRequest(
    request,
    tickets: tickets ?? [ticket],
    roleCard: holdsRole ? roleCard : null,
  );

  Future<VettingException> refusalOf(TrustTaskDocument request) async {
    try {
      await applicant.accepted(
        toApplicant.sent.last,
        request: request,
        communityDid: community.did,
        vetterRole: 'vetter',
      );
    } on VettingException catch (error) {
      return error;
    }
    fail('the applicant took a refusal for an acceptance');
  }

  test('vets an applicant end to end, as applicants check it', () async {
    final sentRequest = await request(
      VettingTicket.parse('${ticket.scanned}')!,
    );

    final taken = (await take(sentRequest))!;
    expect(taken.ticket!.usesLeft, 0);
    final accepted = await applicant.accepted(
      toApplicant.sent.last,
      request: sentRequest,
      communityDid: community.did,
      vetterRole: 'vetter',
    );

    final session = await vetter.openSession(
      taken.accepted!,
      requiredClaims: ['name.legal'],
    );
    final applicantSession = applicant.openSession(
      toApplicant.sent.last,
      vetter: accepted,
      communityDid: community.did,
    );
    expect(applicantSession.matchCode, session.matchCode);

    final sentCard = await applicant.sendCard(
      applicantSession,
      claims: const [
        VettingCardClaim(type: 'name.legal', value: 'Ada Lovelace'),
      ],
      salt: newCommitmentSalt(),
      parentThreadId: sentRequest.id,
    );
    final card = (await vetter.receiveCard(
      toVetter.sent.last,
      session: session,
    ))!;
    expect(card.claims.single.value, 'Ada Lovelace');

    final record = await vetter.issue(
      session,
      card: card,
      matchConfirmed: true,
      documentClasses: ['passport'],
    );
    final statement = await applicant.receiveStatement(
      toApplicant.sent.last,
      session: applicantSession,
      sent: sentCard,
      communityDid: community.did,
    );

    expect(statement.vetterDid, vetterPersona.did);
    expect(statement.method, VettingMethod.inPerson);
    expect(statement.claimsVerified, ['name.legal']);
    expect(statement.documentClasses, ['passport']);
    expect(statement.livenessConfirmed, isTrue);
    expect(record.statementId, statement.credential['id']);
    expect(
      record.statementDigestMultibase,
      digestMultibase(statement.credential),
    );
    expect(vta.signed.single, isNot(contains('proof')));
  });

  test(
    'keeps a record of the statement on the VTA, without the applicant',
    () async {
      final sentRequest = await request(ticket.spoken);
      final taken = (await take(sentRequest))!;
      final session = await vetter.openSession(
        taken.accepted!,
        requiredClaims: ['name.legal'],
      );
      await applicant.sendCard(
        applicant.openSession(
          toApplicant.sent.last,
          vetter: await applicant.accepted(
            toApplicant.sent[toApplicant.sent.length - 2],
            request: sentRequest,
            communityDid: community.did,
            vetterRole: 'vetter',
          ),
          communityDid: community.did,
        ),
        claims: const [VettingCardClaim(type: 'name.legal', value: 'Ada')],
        salt: newCommitmentSalt(),
        parentThreadId: sentRequest.id,
      );
      final card = (await vetter.receiveCard(
        toVetter.sent.last,
        session: session,
      ))!;

      final record = await vetter.issue(
        session,
        card: card,
        matchConfirmed: true,
        documentClasses: ['nationalId'],
      );

      final stored = jsonEncode(vta.records);
      expect(
        vta.records.keys.single,
        'ctx/meeting-place/vetting/issued/${record.statementId}',
      );
      expect(stored, isNot(contains(applicantPersona.did)));
      expect(stored, isNot(contains('Ada')));
      expect(
        (await vetter.issuedStatements()).single.toJson(),
        record.toJson(),
      );
    },
  );

  group('takeRequest', () {
    test('accepts a code as the applicant typed it', () async {
      final typed = VettingTicket.spoken(
        community: community.did,
        vetter: vetterPersona.did,
        code: ticket.code.toLowerCase().replaceAll('-', ''),
      )!;

      expect((await take(await request(typed)))?.accepted, isNotNull);
    });

    test('leaves a wrong or used-up code unanswered', () async {
      final wrong = VettingTicket.withCode(
        community: community.did,
        vetter: vetterPersona.did,
        code: ticket.code == 'ZZZZ-ZZZZ' ? 'YYYY-YYYY' : 'ZZZZ-ZZZZ',
      );

      expect(await take(await request(wrong)), isNull);
      expect(
        await take(await request(ticket.spoken), tickets: [ticket.spent()]),
        isNull,
      );
      expect(toApplicant.sent, isEmpty);
    });

    test('refuses a scanned ticket with the wrong secret', () async {
      final forged = VettingTicket.scanned(
        community: community.did,
        vetter: vetterPersona.did,
        ticketId: ticket.id,
        secret: 'A' * 43,
      );
      final sentRequest = await request(forged);

      final taken = await take(sentRequest);

      expect(taken?.refusal, 'vetting/request:invalidTicket');
      expect(taken?.ticket, isNull);
      expect(
        (await refusalOf(sentRequest)).failure,
        VettingFailure.invalidTicket,
      );
    });

    test(
      'refuses while the vetter holds no role card, keeping the ticket',
      () async {
        final sentRequest = await request(ticket.spoken);

        final taken = await take(sentRequest, holdsRole: false);

        expect(taken?.refusal, 'vetting/request:notEligible');
        expect(taken?.ticket, isNull);
        expect(
          (await refusalOf(sentRequest)).failure,
          VettingFailure.notVetter,
        );
      },
    );

    test('refuses hidden vetting', () async {
      final hidden = await TrustTaskDocument.create(
        type: VettingTask.request,
        issuer: applicantPersona.did,
        recipient: vetterPersona.did,
        payload: {
          'community': community.did,
          'joinDid': applicantPersona.did,
          'ticket': ticket.spoken.toJson(),
        },
        ext: {
          'org.openvtc.hidden-vetting': {'suite': 'ps-ddh-bls12381', 'id': 'h'},
        },
      ).sign(applicantKeys.signer, purpose: ProofPurpose.authentication);

      expect(
        (await take(hidden))?.refusal,
        'vetting/request:methodUnavailable',
      );
    });

    test(
      'ignores a request for another community or joining as another',
      () async {
        for (final payload in [
          {'community': 'did:key:other'},
          {'joinDid': 'did:key:other'},
        ]) {
          final odd = await TrustTaskDocument.create(
            type: VettingTask.request,
            issuer: applicantPersona.did,
            recipient: vetterPersona.did,
            payload: {
              'community': community.did,
              'joinDid': applicantPersona.did,
              'ticket': ticket.spoken.toJson(),
              ...payload,
            },
          ).sign(applicantKeys.signer, purpose: ProofPurpose.authentication);

          expect(await take(odd), isNull);
        }
        expect(toApplicant.sent, isEmpty);
      },
    );
  });

  group('after a request is accepted', () {
    late VetterRequest accepted;
    late AcceptedVetter acceptedByApplicant;

    setUp(() async {
      final sentRequest = await request(ticket.spoken);
      accepted = (await take(sentRequest))!.accepted!;
      acceptedByApplicant = await applicant.accepted(
        toApplicant.sent.last,
        request: sentRequest,
        communityDid: community.did,
        vetterRole: 'vetter',
      );
    });

    test('opens a session the applicant reads', () async {
      final session = await vetter.openSession(
        accepted,
        requiredClaims: ['name.legal', 'person.birthDate'],
      );

      final read = applicant.openSession(
        toApplicant.sent.last,
        vetter: acceptedByApplicant,
        communityDid: community.did,
      );
      expect(read.requiredClaims, ['name.legal', 'person.birthDate']);
      expect(read.method, VettingMethod.inPerson);
      expect(session.expiresAt, now.add(VettingVetter.sessionValidity));
      expect(session.document.parentThreadId, accepted.threadId);
      expect(
        VetterSession.fromJson(session.toJson()).matchCode,
        session.matchCode,
      );
    });

    test('issues nothing before the match code is confirmed', () async {
      final session = await vetter.openSession(
        accepted,
        requiredClaims: ['name.legal'],
      );
      await applicant.sendCard(
        applicant.openSession(
          toApplicant.sent.last,
          vetter: acceptedByApplicant,
          communityDid: community.did,
        ),
        claims: const [VettingCardClaim(type: 'name.legal', value: 'Ada')],
        salt: newCommitmentSalt(),
        parentThreadId: accepted.requestDocumentId,
      );
      final card = (await vetter.receiveCard(
        toVetter.sent.last,
        session: session,
      ))!;
      final sent = toApplicant.sent.length;

      await expectLater(
        vetter.issue(
          session,
          card: card,
          matchConfirmed: false,
          documentClasses: ['passport'],
        ),
        throwsStateError,
      );
      expect(toApplicant.sent.length, sent);
      expect(vta.records, isEmpty);
    });

    test('declines, as the applicant reads it', () async {
      await vetter.decline(accepted, code: 'couldNotVerify');

      final decline = applicant.declined(
        toApplicant.sent.last,
        vetter: acceptedByApplicant,
      );
      expect(decline.code, 'couldNotVerify');
    });

    test('reads the applicant ending the request', () async {
      final ended = await TrustTaskDocument.create(
        type: VettingTask.decline,
        issuer: applicantPersona.did,
        recipient: vetterPersona.did,
        payload: {'requestId': accepted.requestId},
      ).sign(applicantKeys.signer, purpose: ProofPurpose.authentication);

      expect(vetter.isDeclinedBy(ended, accepted), isTrue);
      expect(
        VetterRequest.fromJson(accepted.toJson()).requestId,
        accepted.requestId,
      );
    });
  });
}
