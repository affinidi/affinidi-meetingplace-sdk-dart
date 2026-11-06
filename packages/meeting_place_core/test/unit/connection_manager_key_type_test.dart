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

/// A mediator whose DID agrees keys over X25519 only, as a `did:webvh`
/// mediator with an Ed25519 identity does.
Future<DidDocument> _x25519OnlyMediator() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  await wallet.generateKey(keyId: 'mediator', keyType: KeyType.ed25519);
  final manager = DidKeyManager(store: InMemoryDidStore(), wallet: wallet);
  await manager.addVerificationMethod('mediator');
  return manager.getDidDocument();
}

/// The multibase prefix of an X25519 public key.
const _x25519Multibase = 'z6LS';

void main() {
  final baseHost = Uri.parse('https://mpx.example');
  late Wallet wallet;
  late InMemoryKeyStore keys;
  late ConnectionManager manager;

  setUp(() {
    keys = InMemoryKeyStore();
    wallet = PersistentWallet(keys);
    manager = ConnectionManager(keyRepository: _KeyRepository());
  });

  Future<void> expectX25519Agreement(DidManager didManager) async {
    final document = await didManager.getDidDocument();
    final agreement = document.keyAgreement.first.id;
    final method = document.verificationMethod.firstWhere(
      (method) => method.id == agreement,
    );
    expect(method.toJson()['publicKeyMultibase'], startsWith(_x25519Multibase));
    expect(
      document.matchKeysInKeyAgreement(
        otherDidDocuments: [await _x25519OnlyMediator()],
      ),
      isNotEmpty,
    );
  }

  test('makes a new did:key on Ed25519, agreeing over X25519', () async {
    final didManager = await manager.generateDid(wallet);

    final document = await didManager.getDidDocument();
    final key = await wallet.getPublicKey(
      (await didManager.getWalletKeyId(document.authentication.single.id))!,
    );
    expect(key.type, KeyType.ed25519);
    await expectX25519Agreement(didManager);
  });

  test('makes a new did:web on Ed25519, agreeing over X25519', () async {
    final didManager = await manager.generateDidWeb(wallet, baseHost: baseHost);

    await expectX25519Agreement(didManager);
  });

  test('gives a new did:web a P-256 key to agree with the control '
      'plane', () async {
    final didManager = await manager.generateDidWeb(wallet, baseHost: baseHost);

    final document = await didManager.getDidDocument();
    expect(document.keyAgreement, hasLength(2));
    final controlPlane = document.keyAgreement.last.id;
    final key = await wallet.getPublicKey(
      (await didManager.getWalletKeyId(controlPlane))!,
    );
    expect(key.type, KeyType.p256);
    expect(document.authentication.map((method) => method.id), [
      isNot(controlPlane),
    ]);
  });

  test('keeps a did:web made before without a control plane key', () async {
    const keyId = "m/44'/60'/0'/0'/7'";
    await wallet.generateKey(keyId: keyId, keyType: KeyType.ed25519);
    final existing = DidWebManager(
      store: InMemoryDidStore(),
      wallet: wallet,
      domain: Uri.parse('https://mpx.example/user/before'),
    );
    await existing.addVerificationMethod(
      keyId,
      relationships: {
        VerificationRelationship.authentication,
        VerificationRelationship.keyAgreement,
        VerificationRelationship.assertionMethod,
      },
    );
    final created = await existing.getDidDocument();
    final repository = _KeyRepository();
    await repository.saveKeyIdForDid(keyId: keyId, did: created.id);

    final restored = await (await ConnectionManager(
      keyRepository: repository,
    ).getDidManagerForDid(wallet, created.id)).getDidDocument();

    expect(restored.toJson(), created.toJson());
    expect(restored.keyAgreement, hasLength(1));
  });

  test('seals a message the new DID opens over X25519', () async {
    final didManager = await manager.generateDid(wallet);
    final document = await didManager.getDidDocument();
    final sender = await manager.generateDid(
      PersistentWallet(InMemoryKeyStore()),
    );
    final senderDocument = await sender.getDidDocument();
    final senderKeyId = senderDocument.keyAgreement.first.id;
    final message = PlainTextMessage(
      id: 'urn:uuid:hello',
      type: Uri.parse('https://example.com/hello'),
      from: senderDocument.id,
      to: [document.id],
      body: const {'text': 'hello'},
    );

    final sealed = await EncryptedMessage.packWithAuthentication(
      message,
      keyPair: await sender.getKeyPairByDidKeyId(senderKeyId),
      didKeyId: senderKeyId,
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
  });

  test('makes the root DID on P-256, as the control plane accepts', () async {
    final didManager = await manager.generateRootDid(wallet);

    final document = await didManager.getDidDocument();
    final key = await wallet.getPublicKey(
      (await didManager.getWalletKeyId(document.authentication.single.id))!,
    );
    expect(key.type, KeyType.p256);
  });

  test('keeps the P-256 key of a DID made before', () async {
    const keyId = "m/44'/60'/0'/0'/7'";
    await wallet.generateKey(keyId: keyId, keyType: KeyType.p256);
    final existing = DidKeyManager(store: InMemoryDidStore(), wallet: wallet);
    await existing.addVerificationMethod(keyId);
    final did = (await existing.getDidDocument()).id;
    final repository = _KeyRepository();
    await repository.saveKeyIdForDid(keyId: keyId, did: did);

    final restored = await ConnectionManager(
      keyRepository: repository,
    ).getDidManagerForDid(wallet, did);

    expect((await restored.getDidDocument()).id, did);
    expect((await wallet.getPublicKey(keyId)).type, KeyType.p256);
  });
}
