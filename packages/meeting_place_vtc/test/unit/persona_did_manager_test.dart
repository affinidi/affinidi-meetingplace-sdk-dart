import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';

void main() {
  late FakePersona persona;
  late PersonaDidManager manager;

  Matcher failsWith(MeetingPlaceVtcSDKErrorCode code) => throwsA(
    isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
  );

  /// A `did:key` with its key in a [DidManager], as a peer of the persona.
  Future<(String, Ed25519KeyPair, DidManager)> peer() async {
    final keyStore = InMemoryKeyStore();
    final (keyPair, _) = Ed25519KeyPair.generate();
    await keyStore.set(
      'peer',
      StoredKey(
        keyType: KeyType.ed25519,
        privateKeyBytes: Uint8List.fromList(
          ed.newKeyFromSeed(keyPair.getSeed()).bytes,
        ),
      ),
    );
    final didManager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: PersistentWallet(keyStore),
    );
    await didManager.addVerificationMethod('peer');
    final document = await didManager.getDidDocument();
    return (document.id, keyPair, didManager as DidManager);
  }

  PlainTextMessage message({required String from, required String to}) =>
      PlainTextMessage(
        id: 'urn:uuid:message-1',
        type: Uri.parse('https://example.org/test/1.0/hello'),
        from: from,
        to: [to],
        body: const {'hello': 'persona'},
      );

  setUp(() async {
    persona = FakePersona();
    manager = await PersonaDidManager.borrow(
      document: persona.document,
      signingSeed: persona.signingSeed,
      keyAgreementKey: persona.keyAgreementKey,
    );
  });

  group('PersonaDidManager', () {
    test('unseals a message sealed to the persona key agreement key', () async {
      final (peerDid, peerKey, _) = await peer();
      final sealed = await EncryptedMessage.packWithAuthentication(
        message(from: peerDid, to: persona.did),
        keyPair: peerKey,
        didKeyId: DidKey.resolve(peerDid).keyAgreement.first.id,
        recipientDidDocuments: [persona.document],
      );

      final unsealed = await DidcommMessage.unpackToPlainTextMessage(
        message: jsonDecode(jsonEncode(sealed)) as Map<String, dynamic>,
        recipientDidManager: manager,
        expectedMessageWrappingTypes: const [
          MessageWrappingType.authcryptPlaintext,
        ],
      );

      expect(unsealed.from, peerDid);
      expect(unsealed.body, {'hello': 'persona'});
    });

    test('seals a message as the persona', () async {
      final (peerDid, _, peerManager) = await peer();
      final keyAgreementId = manager.keyAgreement.single;
      final sealed = await EncryptedMessage.packWithAuthentication(
        message(from: persona.did, to: peerDid),
        keyPair: await manager.getKeyPairByDidKeyId(keyAgreementId),
        didKeyId: keyAgreementId,
        recipientDidDocuments: [DidKey.resolve(peerDid)],
      );

      final unsealed = await DidcommMessage.unpackToPlainTextMessage(
        message: jsonDecode(jsonEncode(sealed)) as Map<String, dynamic>,
        recipientDidManager: peerManager,
        expectedMessageWrappingTypes: const [
          MessageWrappingType.authcryptPlaintext,
        ],
      );

      expect(unsealed.from, persona.did);
    });

    test('signs as the persona signing key', () async {
      final signer = await manager.getSigner(manager.authentication.first);
      final data = Uint8List.fromList(utf8.encode('signed by the persona'));

      final signature = await signer.sign(data);

      expect(signer.did, persona.did);
      expect(
        ed.verify(ed.PublicKey(persona.signingPublicKey), data, signature),
        isTrue,
      );
    });

    test('signs in to a mediator with the key agreement key', () async {
      final mediator = DidKey.resolve(Ed25519DidKeySigner.generate().did);

      final provider = await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediator,
        didManager: manager,
      );

      expect(provider.didKeyId, manager.keyAgreement.single);
      expect(provider.signer.didKeyId, manager.authentication.first);
    });

    test('refuses a key that is not the persona one', () async {
      final other = FakePersona();

      expect(
        PersonaDidManager.borrow(
          document: persona.document,
          signingSeed: other.signingSeed,
          keyAgreementKey: persona.keyAgreementKey,
        ),
        failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(
        PersonaDidManager.borrow(
          document: persona.document,
          signingSeed: persona.signingSeed,
          keyAgreementKey: other.keyAgreementKey,
        ),
        failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      // Swapped: the signing seed where the key agreement key goes.
      expect(
        PersonaDidManager.borrow(
          document: persona.document,
          signingSeed: persona.keyAgreementKey,
          keyAgreementKey: persona.signingSeed,
        ),
        failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a key of the wrong length', () {
      expect(
        PersonaDidManager.borrow(
          document: persona.document,
          signingSeed: persona.signingSeed.sublist(1),
          keyAgreementKey: persona.keyAgreementKey,
        ),
        failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a persona without a key agreement key', () {
      final signingOnly = DidKey.resolve(
        Ed25519DidKeySigner.generate().did,
      ).toJson()..['keyAgreement'] = <String>[];

      expect(
        PersonaDidManager.borrow(
          document: DidDocument.fromJson(signingOnly),
          signingSeed: persona.signingSeed,
          keyAgreementKey: persona.keyAgreementKey,
        ),
        failsWith(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('lends no key once forgotten', () async {
      final keyAgreementId = manager.keyAgreement.single;

      manager.forget();

      expect(
        manager.getKeyPairByDidKeyId(keyAgreementId),
        throwsA(isA<StateError>()),
      );
    });
  });
}
