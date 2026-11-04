import 'dart:typed_data';

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

class _ExternalKeys implements ExternalSigningKeys {
  final Map<String, ExternalSigningKey> byDid = {};
  int created = 0;

  @override
  Future<ExternalSigningKey> createKey(String did) async {
    final (keyPair, _) = Ed25519KeyPair.generate();
    final key = ExternalSigningKey(
      keyId: 'vta-key-${++created}',
      publicKey: Uint8List.fromList(keyPair.publicKey.bytes),
    );
    return byDid[did] = key;
  }

  @override
  Future<ExternalSigningKey?> findKey(String did) async => byDid[did];

  @override
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String keyId,
  }) => throw UnimplementedError();
}

void main() {
  final baseHost = Uri.parse('https://mpx.example');
  late Wallet wallet;
  late _KeyRepository keyRepository;
  late _ExternalKeys externalKeys;

  setUp(() {
    wallet = PersistentWallet(InMemoryKeyStore());
    keyRepository = _KeyRepository();
    externalKeys = _ExternalKeys();
  });

  String fragment(String id) => id.split('#').last;

  group('ConnectionManager with external signing keys', () {
    test('gives a new did:web an external key as its only assertion '
        'method', () async {
      final manager = ConnectionManager(
        keyRepository: keyRepository,
        externalSigningKeys: externalKeys,
      );

      final didManager = await manager.generateDidWeb(
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

      final assertionKey = await didManager.wallet.getPublicKey(
        (await didManager.getWalletKeyId(assertion))!,
      );
      expect(assertionKey.type, KeyType.ed25519);
      expect(assertionKey.bytes, externalKeys.byDid[document.id]!.publicKey);
      final deviceKey = await didManager.wallet.getPublicKey(
        (await didManager.getWalletKeyId(authentication))!,
      );
      expect(deviceKey.type, KeyType.p256);
      expect(fragment(assertion), isNot(fragment(authentication)));
    });

    test('rebuilds the same document for a known DID', () async {
      final manager = ConnectionManager(
        keyRepository: keyRepository,
        externalSigningKeys: externalKeys,
      );
      final created = await (await manager.generateDidWeb(
        wallet,
        baseHost: baseHost,
      )).getDidDocument();

      final restored = await (await manager.getDidManagerForDid(
        wallet,
        created.id,
      )).getDidDocument();

      expect(restored.toJson(), created.toJson());
      expect(externalKeys.created, 1);
    });

    test('keeps a DID made without an external key as it was', () async {
      final created = await (await ConnectionManager(
        keyRepository: keyRepository,
      ).generateDidWeb(wallet, baseHost: baseHost)).getDidDocument();

      final restored = await (await ConnectionManager(
        keyRepository: keyRepository,
        externalSigningKeys: externalKeys,
      ).getDidManagerForDid(wallet, created.id)).getDidDocument();

      expect(restored.toJson(), created.toJson());
      expect(
        restored.assertionMethod.single.id,
        restored.keyAgreement.single.id,
      );
      expect(externalKeys.created, 0);
    });

    test('gives did:key DIDs no external key', () async {
      final manager = ConnectionManager(
        keyRepository: keyRepository,
        externalSigningKeys: externalKeys,
      );

      final document = await (await manager.generateDid(
        wallet,
      )).getDidDocument();

      expect(document.verificationMethod, hasLength(1));
      expect(externalKeys.created, 0);
    });

    test('never signs raw bytes with an external key', () async {
      final manager = ConnectionManager(
        keyRepository: keyRepository,
        externalSigningKeys: externalKeys,
      );
      final didManager = await manager.generateDidWeb(
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
      await didManager.sign(
        Uint8List.fromList([1, 2, 3]),
        document.authentication.single.id,
      );
    });
  });
}
