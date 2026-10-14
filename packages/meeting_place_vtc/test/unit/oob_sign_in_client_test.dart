import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

const _requestId = 'q3Vn7Zk2Xo9Rt1LwPb4HdA';

TriggerLinkAccepted _trigger({String flow = signInFlow}) {
  return TriggerLinkAccepted(
    from: vtcDid,
    id: _requestId,
    exp: fakeNow + 120,
    flow: flow,
    task: null,
    ignored: const [],
  );
}

Matcher _failsWith(SignInFailure failure, {bool responded = false}) {
  return throwsA(
    isA<SignInException>()
        .having((e) => e.failure, 'failure', failure)
        .having((e) => e.responded, 'responded', responded),
  );
}

void main() {
  late FakeVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeSignInAgent agent;
  late FakeUserVerification userVerification;
  late bool isMember;

  OobSignInClient client() {
    return OobSignInClient(
      isKnownCommunity: (_) async => isMember,
      didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
      transport: TrustTaskHttpTransport(
        dio: Dio()..httpClientAdapter = adapter,
      ),
      now: () => fakeNow,
    );
  }

  void useCommunity(FakeVtc community) {
    vtc = community;
    adapter.handler = community.handle;
  }

  setUp(() {
    adapter = FakeHttpAdapter();
    useCommunity(FakeVtc());
    agent = FakeSignInAgent();
    userVerification = FakeUserVerification();
    isMember = true;
  });

  group('OobSignInClient.claim', () {
    test('claims with a throwaway key and checks the answer', () async {
      final claimed = await client().claim(_trigger());

      expect(claimed.requestId, _requestId);
      expect(claimed.origin, vtcOrigin);
      expect(claimed.decisionDeadline, fakeNow + 120);
      expect(claimed.audience, SignInAudience.member);

      final claim = adapter.requests.single.body;
      expect(claim['type'], OobTask.claim);
      expect(claim['issuer'], claimed.approverKey.did);
      expect(claim['parentThreadId'], _requestId);
      expect(
        (claim['proof'] as Map)['proofPurpose'],
        ProofPurpose.authentication.value,
      );
    });

    test('reads the operator console audience', () async {
      useCommunity(FakeVtc(audience: 'admin'));

      final claimed = await client().claim(_trigger());

      expect(claimed.audience, SignInAudience.admin);
    });

    test('sends nothing for a community this phone has not joined', () {
      isMember = false;

      expect(client().claim(_trigger()), _failsWith(SignInFailure.notAMember));
      expect(adapter.requests, isEmpty);
    });

    test('refuses a flow other than sign-in', () {
      expect(
        client().claim(_trigger(flow: 'vta-claim')),
        _failsWith(SignInFailure.update),
      );
    });

    test('words a code another device claimed first', () {
      vtc.refuseWith = 'auth/oob/claim:alreadyClaimed';

      expect(
        client().claim(_trigger()),
        _failsWith(SignInFailure.alreadyClaimed),
      );
    });

    test('does not believe an answer signed by another key', () async {
      adapter.handler = (request) async {
        final (status, answer) = await vtc.handle(request);
        final proof = Map<String, dynamic>.of(
          (answer! as Map<String, dynamic>)['proof'] as Map<String, dynamic>,
        );
        final forged = await EddsaJcs2022.sign(
          answer as Map<String, dynamic>,
          signer: Ed25519DidKeySigner.generate(),
          purpose: ProofPurpose.assertionMethod,
        );
        (forged['proof'] as Map<String, dynamic>)['verificationMethod'] =
            proof['verificationMethod'];
        return (status, forged);
      };

      expect(client().claim(_trigger()), _failsWith(SignInFailure.badAnswer));
    });
  });

  group('OobSignInClient.prove', () {
    test('identifies the persona and reads the requester', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());

      final proved = await signIn.prove(
        claimed,
        enteredNumber: ' 47 ',
        persona: agent.signInPersona,
        agent: agent,
      );

      expect(proved.sessionKey, vtc.browserKey.did);
      expect(proved.requester.location, 'Berlin, DE');
      expect(proved.requester.sameNetwork, isTrue);
      final prove = adapter.requests.last.body;
      final identify = (prove['payload'] as Map)['identify'] as Map;
      expect(identify['issuer'], agent.persona.did);
      expect(
        (identify['payload'] as Map)['approverKey'],
        claimed.approverKey.did,
      );
    });

    test('sends nothing when the number is not two digits', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());

      expect(
        signIn.prove(
          claimed,
          enteredNumber: '4',
          persona: agent.signInPersona,
          agent: agent,
        ),
        _failsWith(SignInFailure.badNumber),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('reports a wrong number', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());

      expect(
        signIn.prove(
          claimed,
          enteredNumber: '12',
          persona: agent.signInPersona,
          agent: agent,
        ),
        _failsWith(SignInFailure.wrongNumber),
      );
    });

    test('does not trust an agent that changed the document', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());
      agent.tamper = true;

      expect(
        signIn.prove(
          claimed,
          enteredNumber: '47',
          persona: agent.signInPersona,
          agent: agent,
        ),
        _failsWith(SignInFailure.badAnswer),
      );
    });

    test('words a refusal from the agent', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());
      agent.refuseWith = 'oobNotEnrolledDevice';

      expect(
        signIn.prove(
          claimed,
          enteredNumber: '47',
          persona: agent.signInPersona,
          agent: agent,
        ),
        _failsWith(SignInFailure.notEnrolledDevice),
      );
    });
  });

  group('OobSignInClient.approve', () {
    Future<ProvedSignIn> proved(OobSignInClient signIn) async {
      final claimed = await signIn.claim(_trigger());
      return signIn.prove(
        claimed,
        enteredNumber: '47',
        persona: agent.signInPersona,
        agent: agent,
      );
    }

    test('sends a grant bound to the browser key and step 2', () async {
      final signIn = client();
      final signInToApprove = await proved(signIn);

      await signIn.approve(
        signInToApprove,
        agent: agent,
        userVerification: userVerification,
      );

      final grant = vtc.receivedGrant!;
      final payload = grant['payload'] as Map<String, dynamic>;
      expect(grant['issuer'], agent.persona.did);
      expect(payload['sessionKey'], vtc.browserKey.did);
      expect(payload['origin'], vtcOrigin);
      expect(payload['contextDigest'], digestMultibase(signInToApprove.step2));
      expect(payload['notAfter'], fakeNow + grantLifetime.inSeconds);
      expect(signInToApprove.claimed.responded, isTrue);

      final decision =
          (agent.receivedExt.last![uvConsentExtension] as Map)['decision']
              as Map<String, dynamic>;
      expect(decision['issuer'], userVerification.did);
      await expectLater(
        EddsaJcs2022.verify(
          decision,
          purpose: ProofPurpose.assertionMethod,
          resolver: FakeDidResolver(),
          expectedSigner: userVerification.did,
        ),
        completes,
      );
    });

    test(
      'sends nothing when the person cancels the biometric prompt',
      () async {
        final signIn = client();
        final signInToApprove = await proved(signIn);
        userVerification.failWith = UserVerificationError.cancelled;

        await expectLater(
          signIn.approve(
            signInToApprove,
            agent: agent,
            userVerification: userVerification,
          ),
          _failsWith(SignInFailure.uvCancelled),
        );
        expect(vtc.receivedGrant, isNull);
        expect(signInToApprove.claimed.responded, isFalse);
      },
    );

    test(
      'says an agent signing grants for authentication needs an update',
      () async {
        final signIn = client();
        final signInToApprove = await proved(signIn);
        agent.signGrantForAuthentication = true;

        expect(
          signIn.approve(
            signInToApprove,
            agent: agent,
            userVerification: userVerification,
          ),
          _failsWith(SignInFailure.agentNeedsUpdate),
        );
      },
    );

    test('marks a refused respond as responded', () async {
      final signIn = client();
      final signInToApprove = await proved(signIn);
      vtc.refuseWith = 'auth/oob:requestExpired';

      await expectLater(
        signIn.approve(
          signInToApprove,
          agent: agent,
          userVerification: userVerification,
        ),
        _failsWith(SignInFailure.expired, responded: true),
      );
    });
  });

  group('OobSignInClient.cancel', () {
    test('cancels a claimed sign-in', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger());

      expect(await signIn.cancel(claimed), isTrue);
      expect(vtc.cancels, 1);
    });

    test('never cancels a responded sign-in', () async {
      final signIn = client();
      final claimed = await signIn.claim(_trigger())
        ..responded = true;

      expect(() => signIn.cancel(claimed), throwsStateError);
      expect(vtc.cancels, 0);
    });
  });
}
