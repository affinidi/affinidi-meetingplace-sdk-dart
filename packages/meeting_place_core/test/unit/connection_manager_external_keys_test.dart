import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _KeyRepository implements KeyRepository {
  int _index = 1;
  final Map<String, String> _keyIds = {};

  @override
  Future<int> getLastAccountIndex() async => _index;

  @override
  Future<void> setLastAccountIndex(int index) async => _index = index;

  @override
  Future<void> saveKeyIdForDid({
    required String keyId,
    required String did,
  }) async => _keyIds[did] = keyId;

  @override
  Future<String?> findKeyIdByDid({required String did}) async => _keyIds[did];
}

/// Holds each DID's keys as a VTA does, and lends the agreement key.
class _ExternalKeys implements ExternalConnectionKeys {
  final Map<String, ExternalDidKeys> byDid = {};
  final Map<String, Uint8List> _secrets = {};
  final List<String> lent = [];
  int created = 0;

  /// When true, there is nowhere to hold keys, as with no linked VTA.
  bool isOff = false;

  /// When set, lends this secret instead of the one asked for.
  Uint8List? wrongSecret;

  @override
  Future<ExternalDidKeys?> createKeys(String did) async {
    if (isOff) return null;
    created++;
    final (signing, _) = Ed25519KeyPair.generate();
    final (agreement, secret) = P256KeyPair.generate();
    final agreementId = 'vta-agreement-$created';
    _secrets[agreementId] = secret;
    return byDid[did] = ExternalDidKeys(
      signing: ExternalKey(
        keyId: 'vta-signing-$created',
        publicKey: Uint8List.fromList(signing.publicKey.bytes),
      ),
      agreement: ExternalKey(
        keyId: agreementId,
        publicKey: Uint8List.fromList(agreement.publicKey.bytes),
      ),
    );
  }

  @override
  Future<ExternalDidKeys?> findKeys(String did) async => byDid[did];

  @override
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String keyId,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> lendSecret(String keyId) async {
    lent.add(keyId);
    return Uint8List.fromList(wrongSecret ?? _secrets[keyId]!);
  }
}

class _FailingKeys extends _ExternalKeys {
  @override
  Future<ExternalDidKeys?> createKeys(String did) async =>
      throw StateError('VTA unreachable');
}

void main() {
  final baseHost = Uri.parse('https://mpx.example');
  late Wallet wallet;
  late InMemoryKeyStore deviceKeys;
  late _KeyRepository keyRepository;
  late _ExternalKeys externalKeys;

  setUp(() {
    deviceKeys = InMemoryKeyStore();
    wallet = PersistentWallet(deviceKeys);
    keyRepository = _KeyRepository();
    externalKeys = _ExternalKeys();
  });

  ConnectionManager manager([ExternalConnectionKeys? keys]) =>
      ConnectionManager(
        keyRepository: keyRepository,
        externalConnectionKeys: keys ?? externalKeys,
      );

  group('ConnectionManager with external connection keys', () {
    test('makes a new did:web of external keys only', () async {
      final didManager = await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      );
      final document = await didManager.getDidDocument();

      expect(externalKeys.byDid.keys, [document.id]);
      expect(document.verificationMethod, hasLength(2));
      final assertion = document.assertionMethod.single.id;
      final authentication = document.authentication.single.id;
      expect(document.keyAgreement.single.id, authentication);
      expect(assertion, isNot(authentication));

      final held = externalKeys.byDid[document.id]!;
      final assertionKey = await didManager.wallet.getPublicKey(
        (await didManager.getWalletKeyId(assertion))!,
      );
      expect(assertionKey.type, KeyType.ed25519);
      expect(assertionKey.bytes, held.signing.publicKey);
      final agreementKey = await didManager.wallet.getPublicKey(
        (await didManager.getWalletKeyId(authentication))!,
      );
      expect(agreementKey.type, KeyType.p256);
      expect(agreementKey.bytes, held.agreement.publicKey);

      expect(await deviceKeys.contains("m/44'/60'/0'/0'/2'"), isFalse);
      expect(externalKeys.lent, isEmpty);
    });

    test('rebuilds the same document for a known DID', () async {
      final created = await (await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      )).getDidDocument();

      final restored = await (await manager().getDidManagerForDid(
        wallet,
        created.id,
      )).getDidDocument();

      expect(restored.toJson(), created.toJson());
      expect(externalKeys.created, 1);
    });

    test('borrows the agreement key to unseal a message', () async {
      final didManager = await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      );
      final document = await didManager.getDidDocument();
      final peer = await _peer();
      final message = PlainTextMessage(
        id: 'urn:uuid:hello',
        type: Uri.parse('https://example.com/hello'),
        from: (await peer.getDidDocument()).id,
        to: [document.id],
        body: const {'text': 'hello'},
      );
      final sealed = await EncryptedMessage.packWithAuthentication(
        message,
        keyPair: await peer.getKeyPairByDidKeyId(
          (await peer.getDidDocument()).keyAgreement.first.id,
        ),
        didKeyId: (await peer.getDidDocument()).keyAgreement.first.id,
        recipientDidDocuments: [document],
      );

      final opened = await DidcommMessage.unpackToPlainTextMessage(
        message: sealed.toJson(),
        recipientDidManager: didManager,
        expectedMessageWrappingTypes: const [
          MessageWrappingType.authcryptPlaintext,
        ],
      );

      expect(opened.body, {'text': 'hello'});
      expect(externalKeys.lent, [
        externalKeys.byDid[document.id]!.agreement.keyId,
      ]);
    });

    test('signs as the DID with the borrowed agreement key', () async {
      final didManager = await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      );
      final document = await didManager.getDidDocument();
      final data = Uint8List.fromList([1, 2, 3]);

      final signature = await didManager.sign(
        data,
        document.authentication.single.id,
      );

      final held = P256KeyPair.fromPrivateKey(
        await externalKeys.lendSecret(
          externalKeys.byDid[document.id]!.agreement.keyId,
        ),
      );
      expect(await held.verify(data, signature), isTrue);
    });

    test('refuses a lent key the DID does not publish', () async {
      final didManager = await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      );
      final document = await didManager.getDidDocument();
      externalKeys.wrongSecret = P256KeyPair.generate().$2;

      await expectLater(
        didManager.sign(
          Uint8List.fromList([1, 2, 3]),
          document.authentication.single.id,
        ),
        throwsStateError,
      );
    });

    test('keeps a DID made without external keys as it was', () async {
      final created = await (await ConnectionManager(
        keyRepository: keyRepository,
      ).generateDidWeb(wallet, baseHost: baseHost)).getDidDocument();

      final restored = await (await manager().getDidManagerForDid(
        wallet,
        created.id,
      )).getDidDocument();

      expect(restored.toJson(), created.toJson());
      expect(_deviceKeyIds(restored), hasLength(2));
      expect(externalKeys.created, 0);
    });

    test('keeps a new DID on the device when no external keys are '
        'offered', () async {
      externalKeys.isOff = true;

      final document = await (await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      )).getDidDocument();

      expect(_deviceKeyIds(document), hasLength(2));
      expect(externalKeys.created, 0);
    });

    test('fails to make a DID when the external keys cannot be '
        'created', () async {
      await expectLater(
        manager(_FailingKeys()).generateDidWeb(wallet, baseHost: baseHost),
        throwsStateError,
      );
    });

    test('gives did:key DIDs no external keys', () async {
      final document = await (await manager().generateDid(
        wallet,
      )).getDidDocument();

      expect(_deviceKeyIds(document), hasLength(2));
      expect(externalKeys.created, 0);
    });

    test('never signs raw bytes with an external signing key', () async {
      final didManager = await manager().generateDidWeb(
        wallet,
        baseHost: baseHost,
      );
      final document = await didManager.getDidDocument();

      expect(
        () => didManager.sign(
          Uint8List.fromList([1, 2, 3]),
          document.assertionMethod.single.id,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

/// A party that does not use a VTA: a P-256 did:key on its own device.
/// The ids of [document]'s keys when one Ed25519 device key makes them: the
/// key itself, which signs, and the X25519 key derived from it, which
/// agrees keys.
Set<String> _deviceKeyIds(DidDocument document) {
  final agreement = document.keyAgreement.single.id;
  final signing = document.authentication.single.id;
  expect(document.assertionMethod.single.id, signing);
  expect(agreement, isNot(signing));
  final multibase = {
    for (final method in document.verificationMethod)
      method.id: method.toJson()['publicKeyMultibase'],
  };
  expect(multibase[signing], startsWith('z6Mk'));
  expect(multibase[agreement], startsWith('z6LS'));
  return {signing, agreement};
}

Future<DidManager> _peer() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  await wallet.generateKey(keyId: 'peer');
  final manager = DidKeyManager(store: InMemoryDidStore(), wallet: wallet);
  await manager.addVerificationMethod('peer');
  return manager;
}
