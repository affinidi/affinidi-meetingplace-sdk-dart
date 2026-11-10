import 'dart:async';
import 'dart:convert';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';

/// A persona's inbox on its mediator, in memory.
class _FakeInbox implements MediatorInbox {
  final Map<String, Map<String, dynamic>> messages = {};
  final List<String> deleted = [];
  final arrived = StreamController<void>();
  bool isClosed = false;

  @override
  Future<List<String>> listIds() async => messages.keys.toList();

  @override
  Future<Map<String, dynamic>?> fetch(String id) async => messages[id];

  @override
  Future<void> delete(List<String> ids) async {
    deleted.addAll(ids);
    ids.forEach(messages.remove);
  }

  @override
  Stream<void> arrivals() => arrived.stream;

  @override
  Future<void> close() async => isClosed = true;
}

/// Resolves `did:key`s and `did:peer`s, offline.
class _Resolver implements DidResolver {
  @override
  Future<DidDocument> resolveDid(String did) async =>
      did.startsWith('did:key:') ? DidKey.resolve(did) : DidPeer.resolve(did);
}

void main() {
  late Ed25519DidKeySigner community;
  late Ed25519DidKeySigner mediator;
  late FakePersona persona;
  late _FakeInbox inbox;
  late PersonaInbox personaInbox;
  String? openedMediator;

  Matcher failsWith(MeetingPlaceVtcSDKErrorCode code) => throwsA(
    isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
  );

  Map<String, dynamic> card({String? subject, String? issuer}) => {
    '@context': ['https://www.w3.org/ns/credentials/v2'],
    'type': ['VerifiableCredential', 'MembershipCredential'],
    'issuer': issuer ?? community.did,
    'credentialSubject': {'id': subject ?? persona.did},
    'proof': {'type': 'DataIntegrityProof', 'cryptosuite': 'eddsa-jcs-2022'},
  };

  Future<TrustTaskDocument> issue({
    Map<String, dynamic>? credential,
    String type = credentialIssueTask,
    Ed25519DidKeySigner? signer,
  }) => TrustTaskDocument.create(
    type: type,
    issuer: community.did,
    recipient: persona.did,
    payload: {
      'credential_response': {'credential': credential ?? card()},
    },
  ).sign(signer ?? community, purpose: ProofPurpose.authentication);

  /// [body] in a Trust Task envelope from [from], sealed to the persona.
  Future<Map<String, dynamic>> sealed(
    Map<String, dynamic> body, {
    Ed25519DidKeySigner? from,
    bool anonymously = false,
    String type = trustTaskEnvelopeType,
  }) async {
    final sender = from ?? community;
    final message = PlainTextMessage(
      id: 'urn:uuid:${body['id'] ?? 'message'}',
      type: Uri.parse(type),
      // An anoncrypt message names no sender.
      from: anonymously ? null : sender.did,
      to: [persona.did],
      body: body,
    );
    final packed = anonymously
        ? await EncryptedMessage.packAnonymously(
            message,
            keyType: KeyType.ed25519,
            recipientDidDocuments: [persona.document],
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
          )
        : await EncryptedMessage.packWithAuthentication(
            message,
            keyPair: sender.keyPair,
            didKeyId: DidKey.resolve(sender.did).keyAgreement.first.id,
            recipientDidDocuments: [persona.document],
          );
    return jsonDecode(jsonEncode(packed)) as Map<String, dynamic>;
  }

  setUp(() async {
    community = Ed25519DidKeySigner.generate();
    mediator = Ed25519DidKeySigner.generate();
    persona = FakePersona(mediatorDid: mediator.did);
    inbox = _FakeInbox();
    openedMediator = null;
    personaInbox = PersonaInbox(
      persona: await PersonaDidManager.borrow(
        document: persona.document,
        signingSeed: persona.signingSeed,
        keyAgreementKey: persona.keyAgreementKey,
      ),
      didResolver: _Resolver(),
      openInbox:
          ({
            required String mediatorDid,
            required DidDocument mediatorDocument,
            required DidManager manager,
          }) async {
            openedMediator = mediatorDid;
            return inbox;
          },
    );
  });

  group('PersonaInbox', () {
    test('signs in to the mediator the persona names', () async {
      await personaInbox.open();

      expect(openedMediator, mediator.did);
      expect(personaInbox.mediatorDid, mediator.did);
    });

    test('picks up a card the community issued, and leaves it', () async {
      final document = await issue();
      inbox.messages['m-1'] = await sealed(document.toJson());
      await personaInbox.open();

      final pickup = await personaInbox.issuedCredentials(
        issuerDid: community.did,
      );

      expect(pickup.waiting, 1);
      final issued = pickup.credentials.single;
      expect(issued.messageId, 'm-1');
      expect(issued.document.toJson(), document.toJson());
      expect(issued.credential, card());
      expect(inbox.messages, contains('m-1'));
    });

    test('picks up a card sealed anonymously, on its proof', () async {
      inbox.messages['m-1'] = await sealed(
        (await issue()).toJson(),
        anonymously: true,
      );
      await personaInbox.open();

      final pickup = await personaInbox.issuedCredentials(
        issuerDid: community.did,
      );

      expect(pickup.credentials.single.messageId, 'm-1');
    });

    test('leaves everything else where it is', () async {
      final stranger = Ed25519DidKeySigner.generate();
      inbox.messages
        ..['tsp'] = {'not': 'didcomm'}
        ..['stranger'] = await sealed((await issue()).toJson(), from: stranger)
        ..['forged'] = await sealed(
          (await issue()).toJson()
            ..['payload'] = {
              // Signed over another card: the proof no longer holds.
              'credential_response': {
                'credential': {...card(), 'tampered': true},
              },
            },
        )
        ..['other-task'] = await sealed(
          (await issue(type: 'https://trusttasks.org/spec/other/0.1')).toJson(),
        )
        ..['other-subject'] = await sealed(
          (await issue(credential: card(subject: stranger.did))).toJson(),
        )
        ..['other-issuer'] = await sealed(
          (await issue(credential: card(issuer: stranger.did))).toJson(),
        );
      await personaInbox.open();

      final pickup = await personaInbox.issuedCredentials(
        issuerDid: community.did,
      );

      expect(pickup.waiting, 6);
      expect(pickup.credentials, isEmpty);
      expect(inbox.deleted, isEmpty);
    });

    group('group credentials', () {
      const groupDid = 'did:webvh:QmGroup:vtc.example:group-dids:g1';
      const otherGroupDid = 'did:webvh:QmOther:vtc.example:group-dids:g2';

      Map<String, dynamic> grant(String group) => {
        '@context': ['https://www.w3.org/ns/credentials/v2'],
        'type': [
          'VerifiableCredential',
          'DTGCredential',
          'AuthorityCredential',
        ],
        'issuer': community.did,
        'credentialSubject': {
          'id': group,
          'authority': {
            'scope': community.did,
            'actions': ['issue-membership'],
          },
        },
      };

      Future<InboxPickup> pickUp() async {
        await personaInbox.open();
        return personaInbox.groupCredentials(
          communityDid: community.did,
          groupDids: {groupDid},
        );
      }

      test("picks up a group's card and the community's grant to the "
          'group', () async {
        inbox.messages
          ..['card'] = await sealed(
            (await issue(credential: card(issuer: groupDid))).toJson(),
          )
          ..['grant'] = await sealed(
            (await issue(credential: grant(groupDid))).toJson(),
          );

        final pickup = await pickUp();

        expect(
          pickup.credentials.map((issued) => issued.messageId),
          unorderedEquals(['card', 'grant']),
        );
      });

      test("leaves other groups' credentials and the community's own "
          'card', () async {
        inbox.messages
          ..['other-card'] = await sealed(
            (await issue(credential: card(issuer: otherGroupDid))).toJson(),
          )
          ..['other-grant'] = await sealed(
            (await issue(credential: grant(otherGroupDid))).toJson(),
          )
          ..['community-card'] = await sealed((await issue()).toJson());

        final pickup = await pickUp();

        expect(pickup.waiting, 3);
        expect(pickup.credentials, isEmpty);
      });

      test('leaves a group card someone else sends', () async {
        final stranger = Ed25519DidKeySigner.generate();
        inbox.messages['card'] = await sealed(
          (await issue(credential: card(issuer: groupDid))).toJson(),
          from: stranger,
        );

        final pickup = await pickUp();

        expect(pickup.credentials, isEmpty);
      });
    });

    test('removes only what it is asked to', () async {
      inbox.messages
        ..['m-1'] = await sealed((await issue()).toJson())
        ..['m-2'] = {'not': 'didcomm'};
      await personaInbox.open();

      await personaInbox.remove(['m-1']);

      expect(inbox.deleted, ['m-1']);
      expect(inbox.messages.keys, ['m-2']);
    });

    test('refuses a persona that names no mediator', () async {
      final unreachable = FakePersona();
      final noMediator = PersonaInbox(
        persona: await PersonaDidManager.borrow(
          document: unreachable.document,
          signingSeed: unreachable.signingSeed,
          keyAgreementKey: unreachable.keyAgreementKey,
        ),
        didResolver: _Resolver(),
      );

      expect(
        noMediator.open(),
        failsWith(MeetingPlaceVtcSDKErrorCode.signInNotOffered),
      );
    });

    test('says when the mediator cannot be reached', () async {
      final down = PersonaInbox(
        persona: await PersonaDidManager.borrow(
          document: persona.document,
          signingSeed: persona.signingSeed,
          keyAgreementKey: persona.keyAgreementKey,
        ),
        didResolver: _Resolver(),
        openInbox:
            ({
              required String mediatorDid,
              required DidDocument mediatorDocument,
              required DidManager manager,
            }) async => throw StateError('down'),
      );

      expect(
        down.open(),
        failsWith(MeetingPlaceVtcSDKErrorCode.transportFailed),
      );
    });

    group('peerDocuments', () {
      const session = 'https://trusttasks.org/spec/vetting/session/0.1';
      const decline = 'https://trusttasks.org/spec/vetting/decline/0.1';
      late Ed25519DidKeySigner vetter;

      Future<TrustTaskDocument> sent({
        String type = session,
        String? recipient,
      }) => TrustTaskDocument.create(
        type: type,
        issuer: vetter.did,
        recipient: recipient ?? persona.did,
        payload: const {'requestId': 'r-1'},
      ).sign(vetter, purpose: ProofPurpose.authentication);

      setUp(() => vetter = Ed25519DidKeySigner.generate());

      test('picks up what the peer sent, typed as its task', () async {
        final document = await sent();
        inbox.messages['m-1'] = await sealed(
          document.toJson(),
          from: vetter,
          type: session,
        );
        await personaInbox.open();

        final documents = await personaInbox.peerDocuments(
          senderDid: vetter.did,
          types: {session, decline},
        );

        expect(documents.single.messageId, 'm-1');
        expect(documents.single.document.toJson(), document.toJson());
        expect(inbox.messages, contains('m-1'));
      });

      test('leaves everything else where it is', () async {
        final stranger = Ed25519DidKeySigner.generate();
        inbox.messages
          ..['tsp'] = {'not': 'didcomm'}
          ..['envelope'] = await sealed((await sent()).toJson(), from: vetter)
          ..['anonymous'] = await sealed(
            (await sent()).toJson(),
            anonymously: true,
            type: session,
          )
          ..['stranger'] = await sealed(
            (await sent()).toJson(),
            from: stranger,
            type: session,
          )
          ..['mistyped'] = await sealed(
            (await sent(type: decline)).toJson(),
            from: vetter,
            type: session,
          )
          ..['not-asked'] = await sealed(
            (await sent(type: decline)).toJson(),
            from: vetter,
            type: decline,
          )
          ..['forged'] = await sealed(
            // Signed over another payload: the proof no longer holds.
            (await sent()).toJson()..['payload'] = {'requestId': 'r-2'},
            from: vetter,
            type: session,
          )
          ..['for-another'] = await sealed(
            (await sent(recipient: stranger.did)).toJson(),
            from: vetter,
            type: session,
          );
        await personaInbox.open();

        final documents = await personaInbox.peerDocuments(
          senderDid: vetter.did,
          types: {session},
        );

        expect(documents, isEmpty);
        expect(inbox.deleted, isEmpty);
      });

      test('picks up any sender only on what that sender signed', () async {
        final stranger = Ed25519DidKeySigner.generate();
        final fromStranger = await TrustTaskDocument.create(
          type: session,
          issuer: stranger.did,
          recipient: persona.did,
          payload: const {'requestId': 'r-2'},
        ).sign(stranger, purpose: ProofPurpose.authentication);
        inbox.messages
          ..['vetter'] = await sealed(
            (await sent()).toJson(),
            from: vetter,
            type: session,
          )
          ..['stranger'] = await sealed(
            fromStranger.toJson(),
            from: stranger,
            type: session,
          )
          ..['relayed'] = await sealed(
            (await sent()).toJson(),
            from: stranger,
            type: session,
          )
          ..['anonymous'] = await sealed(
            fromStranger.toJson(),
            anonymously: true,
            type: session,
          );
        await personaInbox.open();

        final documents = await personaInbox.peerDocuments(types: {session});

        expect(documents.map((document) => document.messageId), [
          'vetter',
          'stranger',
        ]);
      });
    });

    group('removalNotices', () {
      Map<String, dynamic> removal({String? did}) => {
        'did': did ?? persona.did,
        'code': 'adminRemoved',
        'disposition': 'tombstone',
        'reason': 'Repeated code-of-conduct breach.',
        'decidedAt': '2026-08-23T09:14:02Z',
        'decidedBy': 'did:key:zAdmin',
      };

      Future<TrustTaskDocument> notice({
        Map<String, dynamic>? payload,
        Ed25519DidKeySigner? signer,
      }) => TrustTaskDocument.create(
        type: memberRemovalNoticeTask,
        issuer: (signer ?? community).did,
        recipient: persona.did,
        payload: payload ?? removal(),
      ).sign(signer ?? community, purpose: ProofPurpose.authentication);

      Future<List<RemovalNotice>> pickUp() async {
        await personaInbox.open();
        return personaInbox.removalNotices(communityDid: community.did);
      }

      test('picks up the community removing the persona, and leaves '
          'it', () async {
        final document = await notice();
        inbox.messages['m-1'] = await sealed(document.toJson());

        final found = (await pickUp()).single;

        expect(found.messageId, 'm-1');
        expect(found.document.toJson(), document.toJson());
        expect(found.code, 'adminRemoved');
        expect(found.disposition, 'tombstone');
        expect(found.reason, 'Repeated code-of-conduct breach.');
        expect(found.decidedAt, DateTime.utc(2026, 8, 23, 9, 14, 2));
        expect(found.decidedBy, 'did:key:zAdmin');
        expect(inbox.messages, contains('m-1'));
      });

      test('picks up a notice sealed anonymously, on its proof', () async {
        inbox.messages['m-1'] = await sealed(
          (await notice()).toJson(),
          anonymously: true,
        );

        expect((await pickUp()).single.messageId, 'm-1');
      });

      test('reads a notice without a reason as giving none', () async {
        inbox.messages['m-1'] = await sealed(
          (await notice(payload: removal()..remove('reason'))).toJson(),
        );

        expect((await pickUp()).single.reason, isNull);
      });

      test('leaves everything else where it is', () async {
        final stranger = Ed25519DidKeySigner.generate();
        inbox.messages
          ..['card'] = await sealed((await issue()).toJson())
          ..['stranger'] = await sealed(
            (await notice()).toJson(),
            from: stranger,
          )
          ..['issued-by-another'] = await sealed(
            (await notice(signer: stranger)).toJson(),
          )
          ..['forged'] = await sealed(
            // Signed over another member: the proof no longer holds.
            (await notice()).toJson()..['payload'] = removal(did: stranger.did),
          )
          ..['about-another'] = await sealed(
            (await notice(payload: removal(did: stranger.did))).toJson(),
          )
          ..['incomplete'] = await sealed(
            (await notice(payload: removal()..remove('decidedAt'))).toJson(),
          );

        expect(await pickUp(), isEmpty);
        expect(inbox.deleted, isEmpty);
      });
    });

    group('arrivals', () {
      test('fires each time a message reaches the inbox', () async {
        await personaInbox.open();
        final arrivals = <void>[];
        final listening = personaInbox.arrivals().listen(arrivals.add);
        addTearDown(listening.cancel);

        inbox.arrived
          ..add(null)
          ..add(null);
        await pumpEventQueue();

        expect(arrivals, hasLength(2));
      });

      test('says when the live connection fails', () async {
        await personaInbox.open();
        final failure = expectLater(
          personaInbox.arrivals(),
          emitsError(
            isA<MeetingPlaceVtcSDKException>().having(
              (error) => error.code,
              'code',
              MeetingPlaceVtcSDKErrorCode.transportFailed,
            ),
          ),
        );

        inbox.arrived.addError(StateError('dropped'));

        await failure;
      });

      test('needs the inbox open', () {
        expect(personaInbox.arrivals, throwsStateError);
      });
    });

    test('ends the session on close', () async {
      await personaInbox.open();

      await personaInbox.close();

      expect(inbox.isClosed, isTrue);
    });
  });
}
