import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
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
    adapter
      ..handler = community.handle
      ..getHandler = community.handleGet;
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

    group('a credential criterion', () {
      Future<JoinCredentialRequest> read(
        Object? query, {
        Object? issuers = 'any',
      }) async {
        vtc.manifest = {
          ...vtc.manifest,
          'criteria': [
            {
              'id': 'members',
              'admission': 'automatic',
              'requirementsDigest': 'z3',
              'presentationDefinition': query,
              'credentialIssuers': ?issuers,
            },
          ],
        };
        final manifest = await client().readManifest(vtcDid);
        return manifest.criteria.single.credentials!;
      }

      Map<String, dynamic> credential({
        String format = 'ldp_vc',
        Object? typeValues = const [
          ['VerifiableCredential', 'MembershipCredential'],
        ],
        Map<String, dynamic> extra = const {},
      }) => {
        'id': 'membership',
        'format': format,
        'meta': {'type_values': typeValues},
        ...extra,
      };

      test('reads the types and issuers of W3C credentials', () async {
        final request = await read({
          'credentials': [
            credential(
              typeValues: [
                ['VerifiableCredential', 'MembershipCredential'],
                ['VerifiableCredential', 'RoleCredential'],
              ],
            ),
            credential(),
          ],
        });

        expect(request.readable, isTrue);
        expect(request.issuers, JoinCredentialIssuers.any);
        expect(request.typeAlternatives, [
          [
            ['VerifiableCredential', 'MembershipCredential'],
            ['VerifiableCredential', 'RoleCredential'],
          ],
          [
            ['VerifiableCredential', 'MembershipCredential'],
          ],
        ]);
        expect((request.query['credentials'] as List).length, 2);
      });

      test('reads unknown or absent issuers as the community only', () async {
        final q = {
          'credentials': [credential()],
        };
        expect(
          (await read(q, issuers: null)).issuers,
          JoinCredentialIssuers.community,
        );
        expect(
          (await read(q, issuers: 'everyone')).issuers,
          JoinCredentialIssuers.community,
        );
        expect(
          (await read(q, issuers: 'recognised')).issuers,
          JoinCredentialIssuers.recognised,
        );
      });

      for (final (what, query) in <(String, Object?)>[
        (
          'SD-JWT credentials',
          {
            'credentials': [credential(format: 'dc+sd-jwt')],
          },
        ),
        (
          'claims',
          {
            'credentials': [
              credential(
                extra: {
                  'claims': [
                    {
                      'path': ['name'],
                    },
                  ],
                },
              ),
            ],
          },
        ),
        (
          'credential sets',
          {
            'credentials': [credential()],
            'credential_sets': <Object>[],
          },
        ),
        (
          'trusted authorities',
          {
            'credentials': [
              credential(extra: {'trusted_authorities': <Object>[]}),
            ],
          },
        ),
        (
          'no types',
          {
            'credentials': [credential(typeValues: null)],
          },
        ),
        ('no credentials', {'credentials': <Object>[]}),
        ('a query that is no object', 'members only'),
      ]) {
        test('cannot read one asking for $what', () async {
          final request = await read(query);

          expect(request.readable, isFalse);
        });
      }
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

    test('keeps the manifest as the community sent it', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'criteria': [
          ...vtc.manifest['criteria'] as List,
          {'id': 'undigested', 'admission': 'automatic'},
          {
            'id': 'members',
            'admission': 'automatic',
            'requirementsDigest': 'z3',
            'presentationDefinition': {'credentials': <Object>[]},
            'credentialIssuers': 'any',
          },
        ],
      };

      final manifest = await client().readManifest(vtcDid);

      expect(manifest.document, vtc.manifest);
      expect(() => manifest.document['name'] = 'x', throwsUnsupportedError);
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

    test("reads the community's https logo only", () async {
      vtc.manifest = {
        ...vtc.manifest,
        'branding': {
          'displayName': 'Football club',
          'logoUrl': 'https://club.example/logo.png',
        },
      };
      expect(
        (await client().readManifest(vtcDid)).logoUrl,
        Uri.parse('https://club.example/logo.png'),
      );

      vtc.manifest = {
        ...vtc.manifest,
        'branding': {'logoUrl': 'http://club.example/logo.png'},
      };
      expect((await client().readManifest(vtcDid)).logoUrl, isNull);
    });

    test('reads what the member directory would disclose', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'directoryDisclosure': {
          'fields': [
            {
              'key': 'name',
              'label': 'Name',
              'type': 'text',
              'source': 'member',
              'ceiling': 'members',
              'defaultVisibility': 'members',
              'searchable': true,
            },
            {
              'key': 'role',
              'label': 'Role',
              'description': 'What you do in the club',
              'type': 'text',
              'source': 'admin',
              'ceiling': 'public',
              'defaultVisibility': 'admins',
              'searchable': false,
            },
            {'key': 'broken', 'label': 'Broken', 'source': 'nobody'},
          ],
          'newCard': {'listing': 'listed', 'search': 'byName'},
          'membershipIdentifiers': 'admins',
          'adminNotes': true,
          'externalCards': false,
          'statementDigest': 'zDigest',
        },
      };

      final disclosure = (await client().readManifest(
        vtcDid,
      )).directoryDisclosure!;

      final [name, role] = disclosure.fields;
      expect(name.label, 'Name');
      expect(name.source, DirectoryFieldSource.member);
      expect(name.defaultVisibility, DirectoryAudience.members);
      expect(role.description, 'What you do in the club');
      expect(role.source, DirectoryFieldSource.admin);
      expect(role.ceiling, DirectoryAudience.public);
      expect(disclosure.membershipIdentifiers, DirectoryAudience.admins);
      expect(disclosure.adminNotes, isTrue);
      expect(disclosure.externalCards, isFalse);
    });

    test('reads no disclosure from an incomplete statement', () async {
      vtc.manifest = {
        ...vtc.manifest,
        'directoryDisclosure': {
          'newCard': {'listing': 'hidden', 'search': 'off'},
        },
      };

      expect((await client().readManifest(vtcDid)).directoryDisclosure, isNull);
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

    group('under a chosen way in', () {
      setUp(() {
        vtc.manifest = {
          ...vtc.manifest,
          'criteria': [
            {
              'id': 'open',
              'admission': 'automatic',
              'requirementsDigest': 'z1',
            },
            {
              'id': 'invited',
              'admission': 'automatic',
              'requirementsDigest': 'z2',
              'invitationRequired': true,
            },
            {
              'id': 'reviewed',
              'admission': 'review',
              'requirementsDigest': 'z3',
            },
          ],
        };
      });

      test('lists the open ways in, in the community\'s order', () async {
        final manifest = await client().readManifest(vtcDid);

        expect(manifest.openCriteria.map((c) => c.id), ['open', 'reviewed']);
        expect(manifest.openCriterion?.id, 'open');
      });

      test('submits the chosen criterion\'s digest', () async {
        final manifest = await client().readManifest(vtcDid);

        await client().apply(
          manifest,
          agent: agent,
          persona: agent.signInPersona,
          criterion: manifest.openCriteria.last,
        );

        expect((vtc.received.last['payload'] as Map)['criterion'], 'z3');
      });

      test('refuses a criterion it cannot meet', () async {
        final manifest = await client().readManifest(vtcDid);
        final invited = manifest.criteria.firstWhere((c) => c.id == 'invited');

        await expectLater(
          client().apply(
            manifest,
            agent: agent,
            persona: agent.signInPersona,
            criterion: invited,
          ),
          throwsStateError,
        );
        expect(
          vtc.received.where((d) => d['type'] == JoinTask.submit),
          isEmpty,
        );
      });

      test('refuses a criterion the community does not offer', () async {
        final manifest = await client().readManifest(vtcDid);

        await expectLater(
          client().apply(
            manifest,
            agent: agent,
            persona: agent.signInPersona,
            criterion: const JoinCriterion(
              id: 'open',
              admission: JoinAdmission.automatic,
              requirementsDigest: 'zOther',
            ),
          ),
          throwsStateError,
        );
        expect(
          vtc.received.where((d) => d['type'] == JoinTask.submit),
          isEmpty,
        );
      });
    });

    group('under a credential criterion', () {
      final credentialCriterion = {
        'id': 'members',
        'admission': 'automatic',
        'requirementsDigest': 'zMembers',
        'presentationDefinition': {
          'credentials': [
            {
              'id': 'membership',
              'format': 'ldp_vc',
              'meta': {
                'type_values': [
                  ['VerifiableCredential', 'MembershipCredential'],
                ],
              },
            },
          ],
        },
        'credentialIssuers': 'any',
      };

      setUp(() {
        vtc.manifest = {
          ...vtc.manifest,
          'criteria': [
            {
              'id': 'open',
              'admission': 'automatic',
              'requirementsDigest': 'z1',
            },
            credentialCriterion,
          ],
        };
      });

      Map<String, dynamic> presentationBy(String holder) => {
        '@context': ['https://www.w3.org/ns/credentials/v2'],
        'type': ['VerifiablePresentation'],
        'holder': holder,
        'verifiableCredential': [
          {'id': 'urn:uuid:card'},
        ],
      };

      Future<JoinVerdict> applyUnder(
        String id, {
        Map<String, dynamic>? presentation,
      }) async {
        final manifest = await client().readManifest(vtcDid);
        return client().apply(
          manifest,
          agent: agent,
          persona: agent.signInPersona,
          criterion: manifest.criteria.firstWhere((c) => c.id == id),
          presentation: presentation,
        );
      }

      Iterable<Map<String, dynamic>> submits() =>
          vtc.received.where((d) => d['type'] == JoinTask.submit);

      test('submits the presentation under it', () async {
        final presentation = presentationBy(agent.persona.did);

        await applyUnder('members', presentation: presentation);

        final payload = submits().single['payload'] as Map;
        expect(payload['criterion'], 'zMembers');
        expect(payload['vp'], presentation);
      });

      test('refuses it without a presentation', () async {
        await expectLater(applyUnder('members'), throwsStateError);
        expect(submits(), isEmpty);
      });

      test("refuses another holder's presentation", () async {
        await expectLater(
          applyUnder('members', presentation: presentationBy('did:key:zOther')),
          throwsStateError,
        );
        expect(submits(), isEmpty);
      });

      test('refuses a presentation for an open criterion', () async {
        await expectLater(
          applyUnder('open', presentation: presentationBy(agent.persona.did)),
          throwsStateError,
        );
        expect(submits(), isEmpty);
      });

      test('refuses one asking for credentials it cannot read', () async {
        vtc.manifest = {
          ...vtc.manifest,
          'criteria': [
            {
              ...credentialCriterion,
              'presentationDefinition': {
                'credentials': [
                  {'id': 'pid', 'format': 'dc+sd-jwt'},
                ],
              },
            },
          ],
        };

        await expectLater(
          applyUnder(
            'members',
            presentation: presentationBy(agent.persona.did),
          ),
          throwsStateError,
        );
        expect(submits(), isEmpty);
      });
    });

    test('reads a role credential under its former name', () async {
      final card = (vtc.verdict['with'] as Map)['roleVac'];
      vtc.verdict = {
        'effect': 'allow',
        'with': {'roleVec': card},
      };

      final verdict = await apply() as JoinAdmitted;

      expect(verdict.membershipCard, isNull);
      expect(verdict.roleCard?['id'], 'urn:uuid:vac');
    });

    Map<String, dynamic> withCard(String name, Map<String, dynamic> change) {
      final details = Map<String, dynamic>.of(
        vtc.verdict['with'] as Map<String, dynamic>,
      );
      details[name] = {...details[name] as Map<String, dynamic>, ...change};
      return {'effect': 'allow', 'with': details};
    }

    for (final (what, card, change) in [
      (
        'a membership card for someone else',
        'vmc',
        {
          'credentialSubject': {'id': 'did:key:z6MkSomeoneElse'},
        },
      ),
      (
        'a membership card from another issuer',
        'vmc',
        {'issuer': 'did:web:other.example'},
      ),
      (
        'a membership card of another type',
        'vmc',
        {
          'type': ['VerifiableCredential'],
        },
      ),
      (
        'a role card from another issuer',
        'roleVac',
        {'issuer': 'did:web:other.example'},
      ),
    ]) {
      test('refuses $what', () {
        vtc.verdict = withCard(card, change);

        expect(
          apply(),
          _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
        );
      });
    }

    test('reads a referral, a denial and a request for more', () async {
      vtc.verdict = {
        'effect': 'refer',
        'with': {'queue': 'review'},
      };
      final pending = await apply();
      expect(pending, isA<JoinPending>());
      final receipt = (pending as JoinPending).receipt!;
      final submit = vtc.received.last;
      expect(pending.exchange?.request.toJson(), submit);
      expect(pending.exchange?.answer.issuer, vtcDid);
      expect(receipt.type, JoinTask.submit);
      expect(receipt.documentId, submit['id']);
      expect(receipt.signer, agent.persona.did);
      expect(receipt.cryptosuite, 'eddsa-jcs-2022');
      expect(
        receipt.verificationMethod,
        (submit['proof'] as Map)['verificationMethod'],
      );
      expect(receipt.signedAt, isNotNull);
      expect(receipt.answeredBy, vtcDid);
      expect(receipt.answeredAt, isNotNull);
      expect(receipt.answerCryptosuite, 'eddsa-jcs-2022');
      expect(receipt.answerVerificationMethod, startsWith('$vtcDid#'));

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
      expect((verdict as JoinPending).receipt, isNull);
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

  group('VtcJoinClient.confirmMembership', () {
    Map<String, dynamic> communityCard() => {
      'id': 'urn:uuid:vmc',
      'type': ['VerifiableCredential', 'MembershipCredential'],
      'issuer': vtcDid,
      'validUntil': '2027-10-08T12:00:00Z',
      'credentialSubject': {'id': agent.persona.did},
      'proof': {'type': 'DataIntegrityProof', 'proofValue': 'zSig'},
    };

    Future<void> confirm({String? requestId = 'request-1'}) =>
        client().confirmMembership(
          vtcDid,
          agent: agent,
          persona: agent.vtaPersona,
          signer: agent.signInPersona,
          communityCard: communityCard(),
          requestId: requestId,
        );

    test('hands the community a credential bound to its card', () async {
      await confirm();

      final request = vtc.received.single;
      expect(request['type'], MemberTask.vmc);
      expect(request['issuer'], agent.persona.did);
      final payload = request['payload'] as Map<String, dynamic>;
      expect(payload['requestId'], 'request-1');

      final vc = payload['vc'] as Map<String, dynamic>;
      expect(vc['issuer'], agent.persona.did);
      expect(vc['issuerScope'], 'directed');
      expect(vc['type'], [
        'VerifiableCredential',
        'DTGCredential',
        'MembershipCredential',
      ]);
      expect(vc['validUntil'], '2027-10-08T12:00:00Z');
      final subject = vc['credentialSubject'] as Map;
      expect(subject['id'], vtcDid);
      // Digested without the card's proof, as the community digests it.
      expect(
        subject['digestMultibase'],
        digestMultibase(communityCard()..remove('proof')),
      );
      await expectLater(
        EddsaJcs2022.verify(
          vc,
          purpose: ProofPurpose.assertionMethod,
          resolver: FakeDidResolver(),
          expectedSigner: agent.persona.did,
        ),
        completes,
      );
    });

    test(
      'confirms without the request the community no longer matches',
      () async {
        vtc.vmcRefusals.add('vtc/members/vmc:requestNotApproved');

        await confirm();

        expect(vtc.received, hasLength(2));
        final retried = vtc.received.last['payload'] as Map;
        expect(retried.containsKey('requestId'), isFalse);
        expect(
          retried['vc'],
          (vtc.received.first['payload'] as Map)['vc'],
          reason: 'the same credential, not a second one',
        );
      },
    );

    test('passes on any other refusal', () {
      vtc.vmcRefusals.add('vtc/members/vmc:notAMember');

      expect(confirm(), _throwsCode(MeetingPlaceVtcSDKErrorCode.refused));
    });
  });

  group('VtcJoinClient.hideDirectoryCard', () {
    test('withdraws the card from the directory as the persona', () async {
      await client().hideDirectoryCard(
        vtcDid,
        agent: agent,
        persona: agent.signInPersona,
      );

      final request = vtc.received.single;
      expect(request['type'], MemberTask.directoryCardUpdate);
      expect(request['issuer'], agent.persona.did);
      expect(request['payload'], {
        'discoverability': {
          'listing': 'hidden',
          'search': 'off',
          'external': false,
        },
      });
    });
  });

  group('VtcJoinClient.readProfile', () {
    test('reads the public profile at the Trust Task base', () async {
      final profile = await client().readProfile(vtcDid);

      expect(
        adapter.requests.single.options.uri.toString(),
        '$vtcOrigin/v1/community/public-profile',
      );
      expect(profile.name, 'Football club');
      expect(profile.description, 'Five-a-side on Sundays.');
      expect(profile.logoUrl, Uri.parse('https://club.example/logo.png'));
      expect(profile.website, Uri.parse('https://club.example/'));
      expect(profile.contactEmail, 'hello@club.example');
      expect(profile.personhood.realHuman, isTrue);
      expect(profile.personhood.singleMembership, isFalse);
    });

    test('drops links that are not https', () async {
      vtc.publicProfile = {
        ...vtc.publicProfile,
        'logoUrl': 'http://club.example/logo.png',
        'publicUrl': 'javascript:alert(1)',
      };

      final profile = await client().readProfile(vtcDid);

      expect(profile.logoUrl, isNull);
      expect(profile.website, isNull);
    });

    test("refuses another community's profile", () {
      vtc.publicProfile = {
        ...vtc.publicProfile,
        'communityDid': 'did:web:other.example',
      };

      expect(
        client().readProfile(vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('says when the community publishes no profile', () {
      adapter.getHandler = (_) async => (404, {'error': 'not found'});

      expect(
        client().readProfile(vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.transportFailed),
      );
    });
  });

  group('VtcJoinClient.leave', () {
    Future<LeaveReceipt> leave() =>
        client().leave(vtcDid, agent: agent, persona: agent.signInPersona);

    test('leaves as the persona and reads the receipt', () async {
      final receipt = await leave();

      final request = vtc.received.single;
      expect(request['type'], MemberTask.selfRemove);
      expect(request['issuer'], agent.persona.did);
      expect(request['payload'], isEmpty);
      expect(receipt.did, agent.persona.did);
      expect(receipt.disposition, 'tombstone');
      expect(receipt.removed, isTrue);
    });

    test('keeps the signed request and answer', () async {
      final receipt = await leave();

      final exchange = receipt.exchange!;
      expect(exchange.request.toJson(), vtc.received.single);
      expect(exchange.answer.issuer, vtcDid);
      expect(exchange.answer.threadId, exchange.request.id);
      expect(exchange.answer.payload['disposition'], 'tombstone');
      expect(receipt.receipt!.signer, agent.persona.did);
    });

    test('refuses a receipt for another DID', () {
      vtc.leaveReceiptForOther = true;

      expect(leave(), _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument));
    });

    test('passes on the refusal of a last administrator', () {
      vtc.leaveRefusal = (409, 'conflict');

      expect(
        leave(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>()
              .having(
                (e) => e.code,
                'code',
                MeetingPlaceVtcSDKErrorCode.refused,
              )
              .having((e) => e.httpStatus, 'httpStatus', 409),
        ),
      );
    });

    test('passes on the refusal of a non-member', () {
      vtc.leaveRefusal = (404, 'vtc/members/self-remove:notMember');

      expect(
        leave(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'vtc/members/self-remove:notMember',
          ),
        ),
      );
    });
  });

  group('VtcJoinClient.withdraw', () {
    Future<TrustTaskReceipt> withdraw() => client().withdraw(
      vtcDid,
      requestId: 'request-1',
      agent: agent,
      persona: agent.signInPersona,
    );

    test('withdraws the request as the persona', () async {
      final receipt = await withdraw();

      final request = vtc.received.single;
      expect(request['type'], JoinTask.withdraw);
      expect(request['issuer'], agent.persona.did);
      expect(request['recipient'], vtcDid);
      expect(request['payload'], {'requestId': 'request-1'});
      expect(receipt.type, JoinTask.withdraw);
      expect(receipt.answeredBy, vtcDid);
    });

    test('passes on that the community decided already', () async {
      vtc.withdrawRefusal = 'vtc/join-requests/withdraw:alreadyDecided';

      expect(
        withdraw(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'vtc/join-requests/withdraw:alreadyDecided',
          ),
        ),
      );
    });

    test('refuses an answer that does not withdraw', () async {
      vtc.withdrawNotWithdrawn = true;

      expect(
        withdraw(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
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

      expect(status.status, JoinRequestStatus.approved);
      expect(status.status.isOpen, isFalse);
      expect(status.credentialsDelivered, isFalse);
      final request = vtc.received.single;
      expect(request['issuer'], agent.persona.did);
      expect(request['payload'], {'requestId': 'request-1'});
      expect(status.receipt?.type, JoinTask.status);
      expect(status.receipt?.documentId, request['id']);
      expect(status.receipt?.answeredBy, vtcDid);
    });

    test("gives the community's reason for a rejection", () async {
      vtc
        ..status = 'rejected'
        ..rejectionReason = 'Members only';

      final status = await client().status(
        vtcDid,
        requestId: 'request-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(status.status, JoinRequestStatus.rejected);
      expect(status.reason, 'Members only');
    });

    test('asks for the cards again', () async {
      vtc.status = 'approved';

      await client().status(
        vtcDid,
        requestId: 'request-1',
        agent: agent,
        persona: agent.signInPersona,
        resendCredentials: true,
      );

      expect(vtc.received.single['payload'], {
        'requestId': 'request-1',
        'resendCredentials': true,
      });
    });

    test('reads a deferred request as still open', () async {
      vtc.status = 'deferred';

      final status = await client().status(
        vtcDid,
        requestId: 'request-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(status.status, JoinRequestStatus.deferred);
      expect(status.status.isOpen, isTrue);
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
