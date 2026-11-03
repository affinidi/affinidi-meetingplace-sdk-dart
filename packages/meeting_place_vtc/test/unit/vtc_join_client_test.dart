import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_join_vtc.dart';
import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

void main() {
  late FakeJoinVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeSignInAgent agent;

  VtcJoinClient client() => VtcJoinClient(
    didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
    transport: TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter),
  );

  void useCommunity(FakeJoinVtc community) {
    vtc = community;
    adapter.handler = community.handle;
  }

  Future<JoinVerdict> apply() async {
    final manifest = await client().readManifest(vtcDid);
    return client().apply(manifest, agent: agent, persona: agent.signInPersona);
  }

  setUp(() {
    adapter = FakeHttpAdapter();
    useCommunity(FakeJoinVtc());
    agent = FakeSignInAgent();
  });

  group('VtcJoinClient.readManifest', () {
    test('reads the name and the ways in', () async {
      final manifest = await client().readManifest(vtcDid);

      expect(manifest.communityDid, vtcDid);
      expect(manifest.name, 'Football club');
      expect(manifest.criteria.map((c) => c.id), ['open', 'invited']);
      expect(manifest.canApply, isTrue);
      expect(manifest.admitsAtOnce, isTrue);

      final request = adapter.requests.single;
      expect(request.options.uri.toString(), '$vtcOrigin/v1/trust-tasks');
      expect(request.body['type'], JoinTask.manifest);
      expect(request.body['recipient'], vtcDid);
      expect(request.body['payload'], <String, dynamic>{});
      expect(request.body.containsKey('proof'), isTrue);
    });

    test('works for a community without a sign-in page', () async {
      useCommunity(FakeJoinVtc(signInPortal: false));

      final manifest = await client().readManifest(vtcDid);

      expect(manifest.name, 'Football club');
    });

    test('says when no way in is open to this wallet', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'criteria': [
          {
            'id': 'members',
            'admission': 'automatic',
            'requirementsDigest': 'z3',
            'presentationDefinition': {'credentials': <Object>[]},
            'credentialIssuers': 'any',
          },
          {
            'id': 'vetted',
            'admission': 'review',
            'requirementsDigest': 'z4',
            'vetting': <String, dynamic>{},
          },
        ],
      };

      final manifest = await client().readManifest(vtcDid);

      final [members, vetted] = manifest.criteria;
      expect(members.asksForCredentials, isTrue);
      expect(vetted.asksForVetting, isTrue);
      expect(manifest.openCriterion, isNull);
      expect(manifest.canApply, isFalse);
    });

    test('skips a criterion it cannot name by digest', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'criteria': [
          {'id': 'undigested', 'admission': 'automatic'},
        ],
      };

      final manifest = await client().readManifest(vtcDid);

      expect(manifest.criteria, isEmpty);
      expect(manifest.canApply, isFalse);
    });

    test('reads the profile details the community asks for', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'requestedAttributes': [
          {'type': 'name', 'purpose': 'To greet you'},
          {'type': 'email', 'required': false},
        ],
      };

      final manifest = await client().readManifest(vtcDid);

      final [name, email] = manifest.requestedAttributes;
      expect(name.type, 'name');
      expect(name.required, isTrue, reason: 'absent means required');
      expect(name.purpose, 'To greet you');
      expect(email.required, isFalse);
      expect(manifest.canApply, isTrue);
    });

    test('reads whether new members are listed in the directory', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'directoryDisclosure': {
          'newCard': {'listing': 'hidden', 'search': 'off'},
        },
      };

      final manifest = await client().readManifest(vtcDid);

      expect(manifest.listsNewMembers, isFalse);
    });

    test('refuses the manifest of another community', () async {
      vtc.manifest = {...vtc.manifest, 'communityDid': 'did:web:other.example'};

      expect(
        client().readManifest(vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses an answer not signed by the community', () async {
      vtc.signWithOtherKey = true;

      expect(
        client().readManifest(vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses an answer to another request', () async {
      vtc.answerOtherRequest = true;

      expect(
        client().readManifest(vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });
  });

  group('VtcJoinClient.apply', () {
    test('submits as the persona and returns the cards', () async {
      final verdict = await apply();

      expect(verdict, isA<JoinAdmitted>());
      final admitted = verdict as JoinAdmitted;
      expect(admitted.requestId, 'request-1');
      expect(admitted.role, 'member');
      expect(admitted.credentials.map((c) => c['id']), [
        'urn:uuid:vmc',
        'urn:uuid:vac',
      ]);

      final submit = vtc.received.last;
      expect(submit['type'], JoinTask.submit);
      expect(submit['issuer'], agent.persona.did);
      expect(submit['recipient'], vtcDid);
      expect(submit.containsKey('proof'), isTrue);
      final payload = submit['payload'] as Map;
      expect(payload['criterion'], 'z1');
      expect(payload.containsKey('attributes'), isFalse);
      expect(payload['registryConsent'], isFalse);
      expect((payload['vp'] as Map)['holder'], agent.persona.did);
    });

    test('sends the profile details and registry consent given', () async {
      final manifest = await client().readManifest(vtcDid);

      await client().apply(
        manifest,
        agent: agent,
        persona: agent.signInPersona,
        attributes: const [JoinAttribute(type: 'name', value: 'Sam')],
        registryConsent: true,
      );

      final payload = vtc.received.last['payload'] as Map;
      expect(payload['attributes'], [
        {'type': 'name', 'value': 'Sam'},
      ]);
      expect(payload['registryConsent'], isTrue);
    });

    test('reads a role credential under its former name', () async {
      vtc.verdict = {
        'effect': 'allow',
        'with': {
          'vmc': {'id': 'urn:uuid:vmc'},
          'roleVec': {'id': 'urn:uuid:vec'},
        },
      };

      final verdict = await apply() as JoinAdmitted;

      expect(verdict.credentials.map((c) => c['id']), [
        'urn:uuid:vmc',
        'urn:uuid:vec',
      ]);
    });

    test('reads a referral, a denial and a request for more', () async {
      vtc.verdict = {
        'effect': 'refer',
        'with': {'queue': 'review'},
      };
      expect(await apply(), isA<JoinPending>());

      vtc.verdict = {
        'effect': 'deny',
        'with': {'code': 'closed', 'reason': 'Not now'},
      };
      final denied = await apply();
      expect(denied, isA<JoinDenied>());
      expect((denied as JoinDenied).reason, 'Not now');

      vtc.verdict = {'effect': 'requestMore', 'with': <String, dynamic>{}};
      expect(await apply(), isA<JoinNeedsMore>());
    });

    test('returns the request already open as pending', () async {
      final manifest = await client().readManifest(vtcDid);
      vtc.refusal = {
        'code': 'vtc/join-requests/submit:requestAlreadyOpen',
        'details': {'requestId': 'request-0', 'status': 'pending'},
      };

      final verdict = await client().apply(
        manifest,
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(verdict, isA<JoinPending>());
      expect(verdict.requestId, 'request-0');
    });

    test('passes other refusals on', () async {
      final manifest = await client().readManifest(vtcDid);
      vtc.refusal = {'code': 'vtc/join-requests/submit:notAccepting'};

      expect(
        client().apply(manifest, agent: agent, persona: agent.signInPersona),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'vtc/join-requests/submit:notAccepting',
          ),
        ),
      );
    });

    test('sends nothing when the agent changes the document', () async {
      final manifest = await client().readManifest(vtcDid);
      agent.tamper = true;

      await expectLater(
        client().apply(manifest, agent: agent, persona: agent.signInPersona),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(vtc.received.map((r) => r['type']), [JoinTask.manifest]);
    });
  });

  group('VtcJoinClient.status', () {
    test('asks as the persona where the request stands', () async {
      vtc.status = 'approved';

      final status = await client().status(
        vtcDid,
        requestId: 'request-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(status, JoinRequestStatus.approved);
      expect(status.isOpen, isFalse);
      final request = vtc.received.single;
      expect(request['issuer'], agent.persona.did);
      expect(request['payload'], {'requestId': 'request-1'});
    });

    test('refuses an unknown status', () async {
      vtc.status = 'lost';

      expect(
        client().status(
          vtcDid,
          requestId: 'request-1',
          agent: agent,
          persona: agent.signInPersona,
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });
  });
}
