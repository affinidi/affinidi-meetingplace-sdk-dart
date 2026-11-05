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
  }) async {
    final sender = from ?? community;
    final message = PlainTextMessage(
      id: 'urn:uuid:${body['id'] ?? 'message'}',
      type: Uri.parse(trustTaskEnvelopeType),
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

    test('ends the session on close', () async {
      await personaInbox.open();

      await personaInbox.close();

      expect(inbox.isClosed, isTrue);
    });
  });
}
