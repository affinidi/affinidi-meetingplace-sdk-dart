import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';
import '../utils/fakes.dart';

const _vtcDid = 'did:web:community.example';

void main() {
  late FakeVta vta;
  late FakeHttpAdapter adapter;
  late Ed25519DidKeySigner manager;
  late VtaClient client;

  setUp(() {
    vta = FakeVta();
    adapter = FakeHttpAdapter()..handler = vta.handle;
    manager = Ed25519DidKeySigner.generate();
    client = VtaClient(
      vtaDid: vta.did,
      manager: manager,
      didResolver: FakeDidResolver({vta.did: vta.document}),
      transport: TrustTaskHttpTransport(
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );
  });

  group('VtaClient', () {
    test('authenticates over REST, then sends signed tasks', () async {
      vta.answers[VtaTask.whoAmI] = {
        'roles': ['admin'],
      };

      final whoAmI = await client.whoAmI();

      expect(whoAmI['roles'], ['admin']);
      final [challenge, authenticate, task] = adapter.requests;
      expect(
        challenge.options.uri.toString(),
        'https://vta.example/api/trust-tasks',
      );
      expect(challenge.body.containsKey('proof'), isFalse);
      expect(challenge.body['payload'], {'subject': manager.did});
      expect(authenticate.body['payload'], {
        'sessionId': 'session-1',
        'challenge': 'nonce-1',
      });
      expect(
        (authenticate.body['proof'] as Map)['proofPurpose'],
        'authentication',
      );
      expect(task.options.headers['Authorization'], 'Bearer $fakeVtaToken');
      expect(task.body['issuer'], manager.did);
    });

    test('authenticates again once when the token is rejected', () async {
      await client.whoAmI();
      vta.rejectTokenTimes = 1;

      await client.whoAmI();

      final types = vta.received.map((r) => r['type']).toList();
      expect(types, [
        VtaTask.challenge,
        VtaTask.authenticate,
        VtaTask.whoAmI,
        VtaTask.whoAmI,
        VtaTask.challenge,
        VtaTask.authenticate,
        VtaTask.whoAmI,
      ]);
    });

    test('returns the signed envelope and passes extensions on', () async {
      final signed = {'id': 'urn:uuid:grant', 'proof': <String, dynamic>{}};
      vta.answers[VtaTask.signTrustTask] = {'signedEnvelope': signed};

      final result = await client.signTrustTask(
        entryId: 'entry-1',
        unsignedEnvelope: {'id': 'urn:uuid:grant'},
        ext: {
          'org.openvtc.uv-consent': {'decision': 'd'},
        },
      );

      expect(result, signed);
      final payload = vta.received.last['payload'] as Map<String, dynamic>;
      expect(payload['entryId'], 'entry-1');
      expect(payload['ext'], {
        'org.openvtc.uv-consent': {'decision': 'd'},
      });
    });

    test('reads the local refusal code from details or message', () async {
      vta.refusals[VtaTask.signTrustTask] = {
        'code': 'taskFailed',
        'message': 'vault/sign-trust-task:oobGrantReplayed',
      };

      await expectLater(
        client.signTrustTask(entryId: 'entry-1', unsignedEnvelope: const {}),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'oobGrantReplayed',
          ),
        ),
      );

      vta.refusals[VtaTask.signTrustTask] = {
        'code': 'taskFailed',
        'details': {'code': 'oobUvRequired'},
      };

      await expectLater(
        client.signTrustTask(entryId: 'entry-1', unsignedEnvelope: const {}),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'oobUvRequired',
          ),
        ),
      );
    });

    group('ensureSignInVaultEntry', () {
      const persona = VtaPersona(
        did: 'did:webvh:QmPersona:host.example',
        contextId: 'keyring',
      );

      test('returns the persona entry targeting the community', () async {
        vta.answers[VtaTask.vaultList] = {
          'entries': [
            {
              'id': 'other-community',
              'principalDid': persona.did,
              'secretKind': 'did-self-issued',
              'targets': [
                {'kind': 'did', 'did': 'did:web:other.example'},
              ],
            },
            {
              'id': 'entry-1',
              'principalDid': persona.did,
              'secretKind': 'didSelfIssued',
              'targets': [
                {'kind': 'did', 'did': _vtcDid},
              ],
            },
          ],
        };

        final entryId = await client.ensureSignInVaultEntry(
          vtcDid: _vtcDid,
          persona: persona,
        );

        expect(entryId, 'entry-1');
        expect(
          vta.received.map((r) => r['type']),
          isNot(contains(VtaTask.vaultUpsert)),
        );
      });

      test('creates the entry with a secret sealed to the VTA', () async {
        vta.answers[VtaTask.vaultUpsert] = {
          'entry': {'id': 'entry-new'},
        };

        final entryId = await client.ensureSignInVaultEntry(
          vtcDid: _vtcDid,
          persona: persona,
        );

        expect(entryId, 'entry-new');
        final upsert = vta.received.last['payload'] as Map<String, dynamic>;
        expect(upsert['secretKind'], 'did-self-issued');
        expect(upsert['targets'], [
          {'kind': 'did', 'did': _vtcDid},
        ]);
        final sealed = upsert['sealedSecret'] as Map<String, dynamic>;
        expect(sealed['envelope'], 'didcomm-authcrypt');
        final jwe = jsonDecode(sealed['jwe'] as String) as Map<String, dynamic>;
        expect(
          jwe.keys,
          containsAll(['protected', 'ciphertext', 'recipients']),
        );
        expect(sealed['jwe'], isNot(contains(persona.signingKeyId)));
      });
    });

    test('registers the device with the approval key', () async {
      await client.enrolUserVerificationKey(
        uvDid: 'did:key:z6MkUv',
        displayName: 'Phone',
        platform: 'ios',
      );

      final register = vta.received.last;
      expect(register['type'], VtaTask.deviceRegister);
      final ext = (register['payload'] as Map)['ext'] as Map;
      expect(ext[uvKeyExtension], {
        'kind': 'hardwareKey',
        'did': 'did:key:z6MkUv',
        'hardwareBacked': false,
        'biometricGated': true,
      });
    });

    test('beats instead when the device is already registered', () async {
      vta.refusals[VtaTask.deviceRegister] = {
        'code': 'device/register:alreadyRegistered',
      };

      await client.enrolUserVerificationKey(
        uvDid: 'did:key:z6MkUv',
        displayName: 'Phone',
        platform: 'ios',
      );

      expect(vta.received.last['type'], VtaTask.deviceHeartbeat);
    });

    test('reports why the VTA DID did not resolve', () async {
      final unresolvable = VtaClient(
        vtaDid: 'did:webvh:QmMissing:vta.example',
        manager: manager,
        didResolver: FakeDidResolver(),
      );

      await expectLater(
        unresolvable.whoAmI(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>()
              .having(
                (e) => e.code,
                'code',
                MeetingPlaceVtcSDKErrorCode.didResolutionFailed,
              )
              .having(
                (e) => e.toString(),
                'toString',
                contains('Caused by: Bad state: unknown DID'),
              ),
        ),
      );
    });

    test('lists personas and fetches stored credentials', () async {
      vta.answers[VtaTask.didsList] = {
        'dids': [
          {'did': 'did:webvh:QmA:host.example', 'contextId': 'keyring'},
          {'did': 'missing-context'},
        ],
      };
      vta.answers[VtaTask.credentialsQuery] = {
        'credentials': [
          {'id': 'card-1'},
        ],
      };
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {'id': 'urn:card-1'},
      };

      final personas = await client.listPersonas();
      final cards = await client.credentials('membership');

      expect(personas.single.did, 'did:webvh:QmA:host.example');
      expect(personas.single.signingKeyId, 'did:webvh:QmA:host.example#key-0');
      expect(cards, [
        {'id': 'urn:card-1'},
      ]);
    });
  });
}
