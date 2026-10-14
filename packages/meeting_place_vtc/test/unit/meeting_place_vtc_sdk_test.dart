import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';
import '../utils/fakes.dart';

const _vtcDid = 'did:web:community.example';
const _membership = CommunityMembership(
  communityDid: _vtcDid,
  persona: VtaPersona(
    did: 'did:webvh:QmPersona:host.example',
    contextId: 'keyring',
  ),
);

void main() {
  late FakeVta vta;
  late MeetingPlaceVtcSDK sdk;
  late VtaClient client;

  setUp(() {
    vta = FakeVta();
    sdk = MeetingPlaceVtcSDK(
      didResolver: FakeDidResolver({vta.did: vta.document}),
      dio: Dio()..httpClientAdapter = (FakeHttpAdapter()..handler = vta.handle),
    );
    client = sdk.vtaClient(vtaDid: vta.did, manager: sdk.newManagerKey());
  });

  group('MeetingPlaceVtcSDK', () {
    test('reads a sign-in code with the Meeting Place flows', () {
      final result = sdk.readTriggerLink(
        'https://link.trustoverip.org/t'
        '#_from=did:webvh:QmCommScid:portal.community.example'
        '&_id=q3Vn7Zk2Xo9Rt1LwPb4HdA&_exp=9999999999'
        '&_type=/vti/flow/sign-in/0.1',
      );

      expect(result, isA<TriggerLinkAccepted>());
      expect(result.uiFor(TriggerLinkConfig.meetingPlace), isNull);
    });

    test('prepares a persona: enrols the key, then the vault entry', () async {
      vta.answers[VtaTask.vaultUpsert] = {
        'entry': {'id': 'entry-new'},
      };

      final persona = await sdk.prepareSignIn(
        vta: client,
        membership: _membership,
        userVerificationDid: 'did:key:z6MkUv',
        deviceName: 'Phone',
        platform: 'ios',
      );

      expect(persona.did, _membership.persona.did);
      expect(persona.entryId, 'entry-new');
      expect(
        vta.received.map((request) => request['type']),
        containsAllInOrder([
          VtaTask.deviceRegister,
          VtaTask.vaultList,
          VtaTask.vaultUpsert,
        ]),
      );
    });

    test('words a refusal of the VTA as a sign-in failure', () {
      vta.refusals[VtaTask.deviceRegister] = {
        'code': 'taskFailed',
        'details': {'code': 'notAuthorized'},
      };

      expect(
        sdk.prepareSignIn(
          vta: client,
          membership: _membership,
          userVerificationDid: 'did:key:z6MkUv',
          deviceName: 'Phone',
          platform: 'ios',
        ),
        throwsA(
          isA<SignInException>().having(
            (e) => e.failure,
            'failure',
            SignInFailure.agentRefused,
          ),
        ),
      );
    });
  });
}
