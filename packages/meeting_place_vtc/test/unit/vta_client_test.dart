import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';
import '../utils/fake_vta.dart';
import '../utils/fakes.dart';

const _vtcDid = 'did:web:community.example';

void main() {
  late FakeVta vta;
  late Ed25519DidKeySigner manager;
  late VtaClient client;

  setUp(() {
    vta = FakeVta();
    manager = Ed25519DidKeySigner.generate();
    client = VtaClient(
      vtaDid: vta.did,
      manager: manager,
      didResolver: FakeVtaResolver(vta),
      transport: vta.transport(manager),
    );
  });

  group('VtaClient', () {
    test('sends signed tasks over DIDComm, without a login', () async {
      vta.answers[VtaTask.whoAmI] = {
        'roles': ['admin'],
      };

      final whoAmI = await client.whoAmI();

      expect(whoAmI.roles, {'admin'});
      final [task] = vta.received;
      expect(task['type'], VtaTask.whoAmI);
      expect(task['issuer'], manager.did);
      expect((task['proof'] as Map)['proofPurpose'], 'authentication');
      expect(vta.forwarded.single.next, vta.did);
    });

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

      expect(vta.received.single['type'], VtaTask.ping);
    });

    test('takes a refusal as an answer before any grant', () async {
      vta.refusals[VtaTask.ping] = {'code': 'permissionDenied'};

      await client.checkReachable();
    });

    test('says when the VTA names no DIDComm mediator', () async {
      final restOnly = DidDocument.fromJson(
        DidKey.resolve(vta.did).toJson()
          ..['service'] = [
            {
              'id': '${vta.did}#vta-rest',
              'type': 'VTARest',
              'serviceEndpoint': 'https://vta.example/api',
            },
          ],
      );
      final resolver = FakeDidResolver({vta.did: restOnly});
      final unreachable = VtaClient(
        vtaDid: vta.did,
        manager: manager,
        didResolver: resolver,
        transport: vta.transport(manager, resolver: resolver),
      );

      await expectLater(
        unreachable.checkReachable(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.signInNotOffered,
          ),
        ),
      );
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

    test('signs out of every session, once it has spoken', () async {
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

    test('reads no refusal code from a DID in the message', () async {
      vta.refusals[VtaTask.credentialsPresent] = {
        'code': 'internalError',
        'message': 'holder key did:key:z6MkExample#z6MkExample cannot sign',
      };

      await expectLater(
        client.presentCredential(
          id: 'card-1',
          claims: const ['memberOf'],
          audience: _vtcDid,
          nonce: 'nonce-1',
        ),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'internalError',
          ),
        ),
      );
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
          'addTspService': false,
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
            'addTspService': false,
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
          personaDid: 'did:webvh:QmP:host.example',
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
        // Worn again, so what the persona discloses is the new values.
        expect(payloadOf(VtaTask.localBindingSet), {
          'contextId': 'mpx-1',
          'personaDid': 'did:webvh:QmP:host.example',
          'profileId': '01PROFILE',
        });
        expect(
          vta.received
              .map((task) => task['type'])
              .toList()
              .indexOf(VtaTask.localBindingSet),
          greaterThan(
            vta.received
                .map((task) => task['type'])
                .toList()
                .indexOf(VtaTask.localProfilePut),
          ),
        );
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
          personaDid: 'did:webvh:QmP:host.example',
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

    group('createConnectionKeys', () {
      // did:key multibase of 32 bytes 1..32, multicodec-prefixed.
      final ed25519Key = Ed25519DidKeySigner.fromSeed(
        Uint8List.fromList(List.generate(32, (i) => i)),
      ).did.substring('did:key:'.length);
      final p256Key = toMultiBase(
        Uint8List.fromList([
          0x80,
          0x24,
          ...P256KeyPair.generate().$1.publicKey.bytes,
        ]),
      );

      List<Object?> sent() =>
          vta.received.map((request) => request['type']).toList();

      List<Map<String, dynamic>> payloadsOf(String type) => [
        for (final request in vta.received)
          if (request['type'] == type)
            request['payload'] as Map<String, dynamic>,
      ];

      setUp(() {
        vta.answerTo[VtaTask.keysCreate] = (payload) => {
          'key': {
            'keyId': 'key-${payload['keyType']}',
            'keyType': payload['keyType'],
            'publicKey': payload['keyType'] == 'p256' ? p256Key : ed25519Key,
            'status': 'active',
            'createdAt': '2026-11-04T12:00:00Z',
          },
        };
      });

      test('creates the connections context once, then the keys in '
          'it', () async {
        vta.answers[VtaTask.contextsList] = {
          'contexts': [
            {'id': 'vta'},
          ],
        };

        final keys = await client.createConnectionKeys();

        expect(
          sent(),
          containsAllInOrder([
            VtaTask.contextsList,
            VtaTask.contextsCreate,
            VtaTask.keysCreate,
            VtaTask.keysCreate,
            VtaTask.keysCreate,
          ]),
        );
        expect(
          payloadsOf(VtaTask.contextsCreate).single['id'],
          connectionKeysContextId,
        );
        expect(payloadsOf(VtaTask.keysCreate), [
          {
            'keyType': 'ed25519',
            'contextId': connectionKeysContextId,
            'label': 'Meeting Place connections',
          },
          {
            'keyType': 'ed25519',
            'contextId': connectionKeysContextId,
            'label': 'Meeting Place connections',
          },
          {
            'keyType': 'p256',
            'contextId': connectionKeysContextId,
            'label': 'Meeting Place connections',
          },
        ]);
        expect(keys.signing.keyId, 'key-ed25519');
        expect(keys.signing.publicKey, hasLength(32));
        expect(keys.agreement.keyId, 'key-ed25519');
        expect(keys.agreement.publicKey, hasLength(32));
        expect(keys.controlPlaneAgreement.keyId, 'key-p256');
        expect(keys.controlPlaneAgreement.publicKey, hasLength(33));
      });

      test('reuses the connections context', () async {
        vta.answers[VtaTask.contextsList] = {
          'contexts': [
            {'id': connectionKeysContextId},
          ],
        };

        await client.createConnectionKeys();

        expect(sent(), isNot(contains(VtaTask.contextsCreate)));
      });

      test('refuses a key of another type than it asked for', () {
        vta.answers[VtaTask.contextsList] = {
          'contexts': [
            {'id': connectionKeysContextId},
          ],
        };
        vta.answerTo[VtaTask.keysCreate] = (payload) => {
          'key': {'keyId': 'key-1', 'keyType': 'p256', 'publicKey': p256Key},
        };

        expect(
          client.createConnectionKeys(),
          throwsA(isA<MeetingPlaceVtcSDKException>()),
        );
      });
    });

    group('lendConnectionKey', () {
      test('borrows an Ed25519 seed over DIDComm', () async {
        final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));
        vta.exportedKeys['key-ed25519'] = {
          'keyId': 'key-ed25519',
          'keyType': 'ed25519',
          'privateKeyMultibase': toMultiBase(
            Uint8List.fromList([0x80, 0x26, ...seed]),
          ),
        };

        final lent = await client.lendConnectionKey('key-ed25519');

        expect(lent, seed);
        expect(
          vta.received.single,
          containsPair('payload', {'keyId': 'key-ed25519'}),
        );
        expect(vta.forwarded, hasLength(1));
      });

      test('borrows the P-256 secret of a key created before', () async {
        final secret = Uint8List.fromList(List.generate(32, (i) => i + 1));
        vta.exportedKeys['key-p256'] = {
          'keyId': 'key-p256',
          'keyType': 'p256',
          'privateKeyMultibase': toMultiBase(
            Uint8List.fromList([0x86, 0x26, ...secret]),
          ),
        };

        final lent = await client.lendConnectionKey('key-p256');

        expect(lent, secret);
        expect(
          vta.received.single,
          containsPair('payload', {'keyId': 'key-p256'}),
        );
        expect(vta.forwarded, hasLength(1));
      });

      test('refuses a secret of another type', () {
        vta.exportedKeys['key-p256'] = {
          'privateKeyMultibase': toMultiBase(
            Uint8List.fromList([0x82, 0x26, ...List.filled(32, 1)]),
          ),
        };

        expect(
          client.lendConnectionKey('key-p256'),
          throwsA(isA<MeetingPlaceVtcSDKException>()),
        );
      });

      test('fails when the VTA will not lend the key', () {
        vta.refusals[VtaTask.exportSecret] = {'code': 'permissionDenied'};

        expect(
          client.lendConnectionKey('key-p256'),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.refusalCode,
              'refusalCode',
              'permissionDenied',
            ),
          ),
        );
      });
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

    group('app state', () {
      test('stores a record and returns its version', () async {
        vta.answers[VtaTask.appStatePut] = {
          'contextId': 'ctx',
          'namespace': 'meeting-place',
          'key': 'vetting/issued/s-1',
          'version': 7,
          'wasCreated': true,
          'updatedAt': '2026-11-06T09:00:00Z',
        };

        final version = await client.putAppState(
          contextId: 'ctx',
          namespace: 'meeting-place',
          key: 'vetting/issued/s-1',
          value: const {'statementId': 's-1'},
          expectedVersion: 0,
        );

        expect(version, 7);
        expect(vta.received.last['payload'], {
          'contextId': 'ctx',
          'namespace': 'meeting-place',
          'key': 'vetting/issued/s-1',
          'value': {'statementId': 's-1'},
          'expectedVersion': 0,
        });
      });

      test('lists every page of live records, with values', () async {
        final pages = [
          {
            'records': [
              {'key': 'a', 'version': 1, 'deleted': false, 'value': 1},
              {'key': 'b', 'version': 2, 'deleted': true},
            ],
            'nextCursor': 'next',
          },
          {
            'records': [
              {'key': 'c', 'version': 3, 'deleted': false, 'value': 3},
            ],
          },
        ];
        vta.answerTo[VtaTask.appStateList] = (payload) =>
            pages[payload['cursor'] == 'next' ? 1 : 0];

        final records = await client.listAppState(
          contextId: 'ctx',
          namespace: 'meeting-place',
          prefix: 'vetting/issued/',
        );

        expect(records.map((record) => (record.key, record.value)), [
          ('a', 1),
          ('c', 3),
        ]);
        expect(
          vta.received
              .where((task) => task['type'] == VtaTask.appStateList)
              .first['payload'],
          {
            'contextId': 'ctx',
            'namespace': 'meeting-place',
            'prefix': 'vetting/issued/',
            'includeValues': true,
          },
        );
      });
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

    group('borrowPersonaKeys', () {
      late FakePersona persona;
      late VtaPersona vtaPersona;

      String keyId(VerificationMethod method) =>
          method.id.startsWith('#') ? '${persona.did}${method.id}' : method.id;

      Matcher failsWith(MeetingPlaceVtcSDKErrorCode code) => throwsA(
        isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
      );

      String multikey(List<int> prefix, Uint8List key) =>
          toMultiBase(Uint8List.fromList([...prefix, ...key]));

      void lend({String? signing, String? keyAgreement}) {
        vta.exportedKeys[keyId(persona.document.authentication.first)] = {
          'keyType': 'Ed25519',
          'privateKeyMultibase':
              signing ?? multikey(const [0x80, 0x26], persona.signingSeed),
        };
        vta.exportedKeys[keyId(persona.document.keyAgreement.first)] = {
          'keyType': 'X25519',
          'privateKeyMultibase':
              keyAgreement ??
              multikey(const [0x82, 0x26], persona.keyAgreementKey),
        };
      }

      setUp(() {
        persona = FakePersona();
        vtaPersona = VtaPersona(did: persona.did, contextId: 'persona');
        client = VtaClient(
          vtaDid: vta.did,
          manager: manager,
          didResolver: FakeVtaResolver(vta, {persona.did: persona.document}),
          transport: vta.transport(manager),
        );
      });

      test('borrows both keys over DIDComm, as Multikeys', () async {
        lend();

        final borrowed = await client.borrowPersonaKeys(vtaPersona);

        expect(borrowed.did, persona.did);
        expect(vta.received.map((r) => r['type']), [
          VtaTask.exportSecret,
          VtaTask.exportSecret,
        ]);
        expect(vta.received.map((r) => r['payload']), [
          {'keyId': keyId(persona.document.authentication.first)},
          {'keyId': keyId(persona.document.keyAgreement.first)},
        ]);
        expect(vta.forwarded, hasLength(2));
      });

      test('borrows bare keys the answer names the type of', () async {
        lend(
          signing: toMultiBase(persona.signingSeed),
          keyAgreement: toMultiBase(persona.keyAgreementKey),
        );

        final borrowed = await client.borrowPersonaKeys(vtaPersona);

        expect(borrowed.did, persona.did);
      });

      test(
        'unseals what is sent to the persona with the borrowed keys',
        () async {
          lend();
          final borrowed = await client.borrowPersonaKeys(vtaPersona);
          final sender = Ed25519DidKeySigner.generate();
          final sealed = await EncryptedMessage.packWithAuthentication(
            PlainTextMessage(
              id: 'urn:uuid:card-1',
              type: Uri.parse('https://example.org/test/1.0/card'),
              from: sender.did,
              to: [persona.did],
              body: const {'card': 'membership'},
            ),
            keyPair: sender.keyPair,
            didKeyId: DidKey.resolve(sender.did).keyAgreement.first.id,
            recipientDidDocuments: [persona.document],
          );

          final unsealed = await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(jsonEncode(sealed)) as Map<String, dynamic>,
            recipientDidManager: borrowed,
            expectedMessageWrappingTypes: const [
              MessageWrappingType.authcryptPlaintext,
            ],
          );

          expect(unsealed.body, {'card': 'membership'});
        },
      );

      test('passes on the VTA refusing to lend a key', () async {
        vta.refusals[VtaTask.exportSecret] = {
          'code': 'taskFailed',
          'message': 'keys/export-secret:notExportable',
        };

        await expectLater(
          client.borrowPersonaKeys(vtaPersona),
          throwsA(
            isA<MeetingPlaceVtcSDKException>().having(
              (e) => e.refusalCode,
              'refusalCode',
              'notExportable',
            ),
          ),
        );
      });

      test('refuses a lent key that is not the persona one', () async {
        lend(
          keyAgreement: multikey(const [
            0x82,
            0x26,
          ], FakePersona().keyAgreementKey),
        );

        await expectLater(
          client.borrowPersonaKeys(vtaPersona),
          failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
        );
      });

      test('refuses a lent key it cannot read', () async {
        // An X25519 key where the Ed25519 seed goes.
        lend(signing: multikey(const [0x82, 0x26], persona.signingSeed));

        await expectLater(
          client.borrowPersonaKeys(vtaPersona),
          failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
        );

        lend(signing: 'not multibase');
        await expectLater(
          client.borrowPersonaKeys(vtaPersona),
          failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
        );
      });
    });
  });
}
