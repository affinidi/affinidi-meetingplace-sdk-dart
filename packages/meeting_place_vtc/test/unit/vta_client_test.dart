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

      expect(whoAmI.roles, {'admin'});
      final [challenge, authenticate, task] = adapter.requests;
      expect(
        challenge.options.uri.toString(),
        'https://vta.example/api/trust-tasks',
      );
      expect(challenge.body.containsKey('proof'), isFalse);
      expect(challenge.body['payload'], {'subject': manager.did});
      // The only authenticate version a VTA serves before a session.
      expect(
        authenticate.body['type'],
        'https://trusttasks.org/spec/auth/authenticate/0.3',
      );
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

    test(
      'authenticates again when the token is refused with a document',
      () async {
        await client.whoAmI();
        vta
          ..rejectTokenTimes = 1
          ..rejectTokenWithDocument = true;

        await client.whoAmI();

        final types = vta.received.map((r) => r['type']).skip(3).toList();
        expect(types, [
          VtaTask.whoAmI,
          VtaTask.challenge,
          VtaTask.authenticate,
          VtaTask.whoAmI,
        ]);
      },
    );

    test('refuses a whoami answer signed by another key', () async {
      vta.answerSigner = Ed25519DidKeySigner.generate();

      await expectLater(
        client.whoAmI(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.invalidProof,
          ),
        ),
      );
    });

    test('refuses a whoami answer to another request', () async {
      vta.answerThreadId = 'urn:uuid:other-request';

      await expectLater(
        client.whoAmI(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.invalidProof,
          ),
        ),
      );
    });

    test('checks the VTA answers before any grant', () async {
      await client.checkReachable();

      final [challenge] = adapter.requests;
      expect(challenge.body['type'], VtaTask.challenge);
      expect(challenge.body.containsKey('proof'), isFalse);
    });

    test('says when the VTA DID does not resolve', () async {
      final unresolvable = VtaClient(
        vtaDid: 'did:webvh:QmMissing:vta.example',
        manager: manager,
        didResolver: FakeDidResolver(),
      );

      await expectLater(
        unresolvable.checkReachable(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.didResolutionFailed,
          ),
        ),
      );
    });

    test('signs out of every session, once authenticated', () async {
      await client.signOut();
      expect(vta.received, isEmpty);

      await client.whoAmI();
      await client.signOut();

      final revoke = vta.received.last;
      expect(revoke['type'], VtaTask.revokeSession);
      expect((revoke['payload'] as Map)['all'], isTrue);
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

      test(
        'finds an entry written with the 0.1 spelling of its kind',
        () async {
          vta.answers[VtaTask.vaultList] = {
            'entries': [
              {
                'id': 'entry-0.1',
                'principalDid': persona.did,
                'secretKind': 'did-self-issued',
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

          expect(entryId, 'entry-0.1');
        },
      );

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
        expect(vta.received.last['type'], endsWith('/vault/upsert/0.4'));
        expect(upsert['secretKind'], 'didSelfIssued');
        expect(upsert['targets'], [
          {'kind': 'did', 'did': _vtcDid},
        ]);
        final sealed = upsert['sealedSecret'] as Map<String, dynamic>;
        expect(sealed['envelope'], 'didcommAuthcrypt');
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
      expect(VtaTask.deviceHeartbeat, endsWith('/device/heartbeat/0.3'));
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

    group('held credentials', () {
      const persona = 'did:webvh:QmA:host.example';
      const membership = ['VerifiableCredential', 'MembershipCredential'];

      Map<String, dynamic> sent(String type) =>
          vta.received.lastWhere((r) => r['type'] == type)['payload']
              as Map<String, dynamic>;

      JoinCredentialRequest request(
        JoinCredentialIssuers issuers, [
        List<List<List<String>>> alternatives = const [
          [membership],
        ],
      ]) => JoinCredentialRequest(
        query: const {},
        issuers: issuers,
        typeAlternatives: alternatives,
      );

      test('finds valid credentials by type, without their claims', () async {
        vta.answers[VtaTask.credentialsQuery] = {
          'credentials': [
            {
              'id': 'card-1',
              'types': membership,
              'status': 'valid',
              'issuerDid': _vtcDid,
              'validUntil': '2027-01-01T00:00:00Z',
            },
            {'id': 'no-types', 'status': 'valid'},
          ],
        };

        final held = await client.findCredentials(
          type: 'MembershipCredential',
          issuerDid: _vtcDid,
          subjectDid: persona,
        );

        expect(sent(VtaTask.credentialsQuery), {
          'type': 'MembershipCredential',
          'issuerDid': _vtcDid,
          'subjectDid': persona,
          'status': 'valid',
        });
        final card = held.single;
        expect(card.id, 'card-1');
        expect(card.types, membership);
        expect(card.issuerDid, _vtcDid);
        expect(card.validUntil, DateTime.utc(2027));
      });

      test('finds valid credentials of any type from one issuer', () async {
        await client.findCredentials(issuerDid: _vtcDid, subjectDid: persona);

        expect(sent(VtaTask.credentialsQuery), {
          'issuerDid': _vtcDid,
          'subjectDid': persona,
          'status': 'valid',
        });
      });

      test('matches each credential asked for from the community', () async {
        vta.answers[VtaTask.credentialsQuery] = {
          'credentials': [
            {'id': 'card-1', 'types': membership, 'status': 'valid'},
          ],
        };

        final matches = await client.matchCredentials(
          request(JoinCredentialIssuers.community),
          subjectDid: persona,
          communityDid: _vtcDid,
        );

        expect(matches?.single.id, 'card-1');
        final query = sent(VtaTask.credentialsQuery);
        expect(query['type'], 'MembershipCredential');
        expect(query['issuerDid'], _vtcDid);
        expect(query['subjectDid'], persona);
      });

      test(
        'leaves the issuer to the community when it recognises others',
        () async {
          vta.answers[VtaTask.credentialsQuery] = {
            'credentials': [
              {'id': 'card-1', 'types': membership, 'status': 'valid'},
            ],
          };

          await client.matchCredentials(
            request(JoinCredentialIssuers.recognised),
            subjectDid: persona,
            communityDid: _vtcDid,
          );

          expect(
            sent(VtaTask.credentialsQuery).containsKey('issuerDid'),
            isFalse,
          );
        },
      );

      test('matches only a credential carrying every type', () async {
        vta.answers[VtaTask.credentialsQuery] = {
          'credentials': [
            {
              'id': 'role',
              'types': ['VerifiableCredential', 'RoleCredential'],
              'status': 'valid',
            },
          ],
        };

        final matches = await client.matchCredentials(
          request(JoinCredentialIssuers.any, [
            [
              ['VerifiableCredential', 'RoleCredential', 'AdminCredential'],
            ],
          ]),
          subjectDid: persona,
          communityDid: _vtcDid,
        );

        expect(matches, isNull);
      });

      test('matches nothing for a request it cannot read', () async {
        final matches = await client.matchCredentials(
          request(JoinCredentialIssuers.any, const []),
          subjectDid: persona,
          communityDid: _vtcDid,
        );

        expect(matches, isNull);
        expect(
          vta.received.where((r) => r['type'] == VtaTask.credentialsQuery),
          isEmpty,
        );
      });

      test('presents a credential to a verifier', () async {
        vta.answers[VtaTask.credentialsPresent] = {
          'presentation': {
            'type': ['VerifiablePresentation'],
            'holder': persona,
          },
          'disclosed': ['memberOf'],
        };

        final presented = await client.presentCredential(
          id: 'card-1',
          claims: const ['memberOf'],
          audience: _vtcDid,
          nonce: 'nonce-1',
        );

        expect(sent(VtaTask.credentialsPresent), {
          'id': 'card-1',
          'claims': ['memberOf'],
          'audience': _vtcDid,
          'nonce': 'nonce-1',
        });
        expect(presented.presentation['holder'], persona);
        expect(presented.disclosed, ['memberOf']);
      });

      test('refuses a presentation that is not a W3C one', () {
        vta.answers[VtaTask.credentialsPresent] = {
          'presentation': 'eyJ.sd-jwt~',
          'disclosed': ['memberOf'],
        };

        expect(
          client.presentCredential(
            id: 'card-1',
            claims: const ['memberOf'],
            audience: _vtcDid,
            nonce: 'nonce-1',
          ),
          throwsA(isA<MeetingPlaceVtcSDKException>()),
        );
      });
    });

    group('createPersona', () {
      setUp(() {
        vta.answers[VtaTask.contextsList] = {
          'contexts': [
            {'id': 'keyring'},
            {'id': 'vta'},
          ],
        };
        vta.answers[VtaTask.serversList] = {
          'servers': [
            {'id': 'webvh-1'},
            {'id': 'webvh-2'},
          ],
        };
        vta.answers[VtaTask.didsCreate] = {
          'did': 'did:webvh:QmP:host.example',
          'contextId': 'vta',
          'signingKeyId': 'did:webvh:QmP:host.example#key-0',
        };
      });

      test('publishes a persona in the default context', () async {
        final persona = await client.createPersona(label: 'Football club');

        expect(persona.did, 'did:webvh:QmP:host.example');
        expect(persona.contextId, 'vta');
        expect(persona.signingKeyId, 'did:webvh:QmP:host.example#key-0');
        expect(
          vta.received.last['type'],
          'https://trusttasks.org/spec/vta/webvh/dids/create/1.2',
        );
        expect(vta.received.last['payload'], {
          'contextId': 'vta',
          'serverId': 'webvh-1',
          'label': 'Football club',
          'addMediatorService': true,
          'setPrimary': false,
        });
      });

      test('uses the first context when there is no default', () async {
        vta.answers[VtaTask.contextsList] = {
          'contexts': [
            {'id': 'keyring'},
          ],
        };

        await client.createPersona(label: 'Football club');

        expect((vta.received.last['payload'] as Map)['contextId'], 'keyring');
      });

      test('says when the VTA has no DID hosting server', () async {
        vta.answers[VtaTask.serversList] = {'servers': <Object>[]};

        await expectLater(
          client.createPersona(label: 'Football club'),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.code,
              'code',
              MeetingPlaceVtcSDKErrorCode.didHostingMissing,
            ),
          ),
        );
        expect(
          vta.received.map((request) => request['type']),
          isNot(contains(VtaTask.didsCreate)),
        );
      });
    });

    group('identities', () {
      const profile = VtaProfile(
        displayName: 'Ada',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        mobile: ' ',
      );

      List<Object?> sent() =>
          vta.received.map((request) => request['type']).toList();

      Map<String, dynamic> payloadOf(String type) =>
          vta.received.lastWhere(
                (request) => request['type'] == type,
              )['payload']
              as Map<String, dynamic>;

      setUp(() {
        vta.answers[VtaTask.serversList] = {
          'servers': [
            {'id': 'dids'},
          ],
        };
        vta.answers[VtaTask.didsCreate] = {
          'did': 'did:webvh:QmP:host.example:ada',
          'contextId': 'ignored',
          'signingKeyId': 'did:webvh:QmP:host.example:ada#key-0',
        };
        vta.answers[VtaTask.profileCompose] = {
          'profileId': '01PROFILE',
          'scope': 'local',
          'version': 1,
        };
      });

      test(
        'creates a context, a persona in it, and a profile it wears',
        () async {
          final identity = await client.createIdentity(profile);

          expect(
            sent(),
            containsAllInOrder([
              VtaTask.serversList,
              VtaTask.contextsCreate,
              VtaTask.didsCreate,
              VtaTask.profileCompose,
            ]),
          );
          final contextId = payloadOf(VtaTask.contextsCreate)['id'] as String;
          expect(contextId, startsWith('mpx-'));
          expect(payloadOf(VtaTask.didsCreate), {
            'contextId': contextId,
            'serverId': 'dids',
            'label': 'Meeting Place identity',
            'addMediatorService': true,
            'setPrimary': true,
          });
          expect(payloadOf(VtaTask.profileCompose), {
            'contextId': contextId,
            'name': 'Meeting Place identity',
            'personaDid': 'did:webvh:QmP:host.example:ada',
            'claims': [
              {
                'type': 'name.display',
                'valueType': 'string',
                'value': 'Ada',
                'share': 'local',
                'slot': 'displayName',
              },
              {
                'type': 'name.given',
                'valueType': 'string',
                'value': 'Ada',
                'share': 'local',
              },
              {
                'type': 'name.family',
                'valueType': 'string',
                'value': 'Lovelace',
                'share': 'local',
              },
              {
                'type': 'email.personal',
                'valueType': 'string',
                'value': 'ada@example.com',
                'share': 'local',
                'slot': 'primaryEmail',
              },
            ],
          });
          expect(identity.persona.did, 'did:webvh:QmP:host.example:ada');
          expect(identity.profileId, '01PROFILE');
          expect(identity.persona.signingKeyId, endsWith('#key-0'));
        },
      );

      test('deletes the context when a later step fails', () async {
        vta.refusals[VtaTask.profileCompose] = {
          'code': 'persona/profile/compose:noPersonaHere',
        };

        await expectLater(
          client.createIdentity(profile),
          throwsA(isA<MeetingPlaceVtcSDKException>()),
        );

        final contextId = payloadOf(VtaTask.contextsCreate)['id'];
        expect(sent().last, VtaTask.contextsDelete);
        expect(payloadOf(VtaTask.contextsDelete), {
          'id': contextId,
          'force': true,
        });
      });

      test('creates nothing without a DID hosting server', () async {
        vta.answers[VtaTask.serversList] = {'servers': <Object>[]};

        await expectLater(
          client.createIdentity(profile),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.code,
              'code',
              MeetingPlaceVtcSDKErrorCode.didHostingMissing,
            ),
          ),
        );
        expect(sent(), isNot(contains(VtaTask.contextsCreate)));
      });

      test('reads and replaces the profile kept in the context', () async {
        vta.answers[VtaTask.localProfileGet] = {
          'profile': {
            'profileId': '01PROFILE',
            'name': 'Meeting Place identity',
            'version': 2,
            'entries': [
              {
                'slot': 'displayName',
                'inline': {
                  'type': 'name.display',
                  'valueType': 'string',
                  'value': 'Ada',
                },
              },
              {
                'inline': {
                  'type': 'phone.mobile',
                  'valueType': 'string',
                  'value': '+44 20',
                },
              },
            ],
          },
        };

        final read = await client.profile(
          contextId: 'mpx-1',
          profileId: '01PROFILE',
        );
        await client.updateProfile(
          contextId: 'mpx-1',
          profileId: '01PROFILE',
          profile: const VtaProfile(displayName: 'Ada L', firstName: 'Ada'),
        );

        expect(read.displayName, 'Ada');
        expect(read.firstName, '');
        expect(read.mobile, '+44 20');
        expect(read.email, isNull);
        expect(payloadOf(VtaTask.localProfilePut), {
          'contextId': 'mpx-1',
          'profileId': '01PROFILE',
          'name': 'Meeting Place identity',
          'entries': [
            {
              'inline': {
                'type': 'name.display',
                'valueType': 'string',
                'value': 'Ada L',
              },
              'slot': 'displayName',
            },
            {
              'inline': {
                'type': 'name.given',
                'valueType': 'string',
                'value': 'Ada',
              },
            },
          ],
        });
      });

      test('reads the profile as the VTA keeps it', () async {
        final document = {
          'profileId': '01PROFILE',
          'name': 'Meeting Place identity',
          'version': 2,
          'entries': [
            {
              'slot': 'displayName',
              'inline': {
                'type': 'name.display',
                'valueType': 'string',
                'value': 'Ada',
              },
            },
          ],
        };
        vta.answers[VtaTask.localProfileGet] = {'profile': document};

        final read = await client.profileDocument(
          contextId: 'mpx-1',
          profileId: '01PROFILE',
        );

        expect(read, document);
        expect(payloadOf(VtaTask.localProfileGet), {
          'contextId': 'mpx-1',
          'profileId': '01PROFILE',
        });
      });

      test('says when the VTA answers without a profile', () async {
        vta.answers[VtaTask.localProfileGet] = <String, dynamic>{};

        await expectLater(
          client.profileDocument(contextId: 'mpx-1', profileId: '01PROFILE'),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.code,
              'code',
              MeetingPlaceVtcSDKErrorCode.invalidDocument,
            ),
          ),
        );
      });

      test('keeps a thumbnail in the profile, up to the cap', () async {
        final thumbnail = 'A' * VtaProfile.maxThumbnailLength;
        vta.answers[VtaTask.localProfileGet] = {
          'profile': {
            'entries': [
              {
                'slot': 'avatar',
                'inline': {
                  'type': 'x:photo.thumbnail',
                  'valueType': 'string',
                  'value': thumbnail,
                },
              },
            ],
          },
        };

        final read = await client.profile(
          contextId: 'mpx-1',
          profileId: '01PROFILE',
        );
        await client.updateProfile(
          contextId: 'mpx-1',
          profileId: '01PROFILE',
          profile: VtaProfile(
            displayName: 'Ada',
            firstName: 'Ada',
            thumbnail: thumbnail,
          ),
        );

        expect(read.thumbnail, thumbnail);
        expect((payloadOf(VtaTask.localProfilePut)['entries'] as List).last, {
          'inline': {
            'type': 'x:photo.thumbnail',
            'valueType': 'string',
            'value': thumbnail,
          },
          'slot': 'avatar',
        });
      });

      test('refuses to send a thumbnail over the cap', () async {
        final oversized = VtaProfile(
          displayName: 'Ada',
          firstName: 'Ada',
          thumbnail: 'A' * (VtaProfile.maxThumbnailLength + 1),
        );

        expect(oversized.toClaims, throwsArgumentError);
        await expectLater(
          client.createIdentity(oversized),
          throwsArgumentError,
        );
        expect(sent(), isNot(contains(VtaTask.profileCompose)));
      });

      test('drops a thumbnail over the cap read from the VTA', () {
        final read = VtaProfile.fromEntries([
          {
            'inline': {
              'type': 'x:photo.thumbnail',
              'valueType': 'string',
              'value': 'A' * (VtaProfile.maxThumbnailLength + 1),
            },
          },
        ]);

        expect(read.thumbnail, isNull);
      });

      test('retires the profile, then deletes the context', () async {
        await client.deleteIdentity(contextId: 'mpx-1', profileId: '01PROFILE');

        expect(sent().sublist(sent().length - 2), [
          VtaTask.profileRetire,
          VtaTask.contextsDelete,
        ]);
        expect(payloadOf(VtaTask.profileRetire), {
          'contextId': 'mpx-1',
          'profileId': '01PROFILE',
        });
        expect(payloadOf(VtaTask.contextsDelete), {
          'id': 'mpx-1',
          'force': true,
        });
      });

      test('deletes an identity already gone without error', () async {
        vta.refusals[VtaTask.profileRetire] = {
          'code': 'persona/profile/retire:versionConflict',
        };
        vta.refusals[VtaTask.contextsDelete] = {
          'code': 'vta/contexts/delete:notFound',
        };

        await client.deleteIdentity(contextId: 'mpx-1', profileId: '01PROFILE');
      });

      test('says when the context could not be deleted', () async {
        vta.refusals[VtaTask.contextsDelete] = {
          'code': 'vta/contexts/delete:hostCleanupFailed',
        };

        await expectLater(
          client.deleteIdentity(contextId: 'mpx-1', profileId: '01PROFILE'),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.refusalCode,
              'refusalCode',
              'hostCleanupFailed',
            ),
          ),
        );
      });
    });

    test('keeps a credential in the persona context', () async {
      vta.answers[VtaTask.credentialsReceive] = {'status': 'valid'};

      final kept = await client.keepCredential({
        'id': 'urn:card-1',
      }, contextId: 'vta');

      expect(kept, isTrue);
      expect(vta.received.last['type'], VtaTask.credentialsReceive);
      expect(vta.received.last['payload'], {
        'credential': {'id': 'urn:card-1'},
        'contextId': 'vta',
        'id': 'urn:card-1',
      });
    });

    test('says when the VTA finds a card revoked', () async {
      vta.answers[VtaTask.credentialsReceive] = {'status': 'revoked'};

      final kept = await client.keepCredential({
        'id': 'urn:card-1',
      }, contextId: 'vta');

      expect(kept, isFalse);
    });

    test('has the VTA sign a document as a persona', () async {
      final document = {'issuer': 'did:webvh:QmP:host.example', 'id': 'urn:x'};
      vta.answers[VtaTask.signDocument] = {
        'document': {
          ...document,
          'proof': {'proofPurpose': 'assertionMethod'},
        },
      };

      final signed = await client.signDocument(
        keyId: 'did:webvh:QmP:host.example#key-0',
        document: document,
        purpose: 'assertionMethod',
      );

      expect(vta.received.last['payload'], {
        'keyId': 'did:webvh:QmP:host.example#key-0',
        'document': document,
        'proofPurpose': 'assertionMethod',
      });
      expect(signed['proof'], isNotNull);
    });

    test('refuses a signed document without a proof', () {
      vta.answers[VtaTask.signDocument] = {
        'document': {'issuer': 'did:webvh:QmP:host.example'},
      };

      expect(
        client.signDocument(
          keyId: 'k',
          document: const {'issuer': 'did:webvh:QmP:host.example'},
          purpose: 'assertionMethod',
        ),
        throwsA(isA<MeetingPlaceVtcSDKException>()),
      );
    });

    group('disclosure', () {
      const persona = VtaPersona(
        did: 'did:webvh:QmP:host.example',
        contextId: 'vta',
      );

      test('previews what the VTA would disclose', () async {
        vta.answers[VtaTask.disclosurePreview] = {
          'previewId': 'preview-1',
          'claims': [
            {'type': 'name', 'value': 'Sam', 'provenance': 'selfAsserted'},
            {'type': 'email', 'stale': true},
          ],
        };

        final preview = await client.previewDisclosure(
          persona: persona,
          verifierDid: _vtcDid,
          requestedClaims: ['name', 'email'],
        );

        expect(vta.received.last['payload'], {
          'contextId': 'vta',
          'personaDid': persona.did,
          'verifierDid': _vtcDid,
          'requestedClaims': ['name', 'email'],
        });
        expect(preview.previewId, 'preview-1');
        final [name, email] = preview.claims;
        expect((name.type, name.value, name.stale), ('name', 'Sam', false));
        expect((email.type, email.value, email.stale), ('email', null, true));
      });

      test('says when the persona has no profile bound', () {
        vta.refusals[VtaTask.disclosurePreview] = {
          'code': 'persona/disclosure/preview:notBound',
        };

        expect(
          client.previewDisclosure(
            persona: persona,
            verifierDid: _vtcDid,
            requestedClaims: ['name'],
          ),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (e) => e.refusalCode,
              'refusalCode',
              'notBound',
            ),
          ),
        );
      });

      test('presents an approved preview', () async {
        vta.answers[VtaTask.disclosurePresent] = {'disclosureId': 'd-1'};

        await client.presentDisclosure(
          persona: persona,
          previewId: 'preview-1',
        );

        expect(vta.received.last['type'], VtaTask.disclosurePresent);
        expect(vta.received.last['payload'], {
          'contextId': 'vta',
          'previewId': 'preview-1',
        });
      });
    });
  });
}
