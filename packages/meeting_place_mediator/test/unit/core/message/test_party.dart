import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

/// A DID with its keys that can send authcrypt messages in tests.
class TestParty {
  TestParty(this.didManager, this.keyPair, this.didDocument);

  final DidManager didManager;
  final KeyPair keyPair;
  final DidDocument didDocument;

  static Future<TestParty> create() async {
    final wallet = PersistentWallet(InMemoryKeyStore());
    final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    const keyId = 'key-1';
    final keyPair = await wallet.generateKey(
      keyId: keyId,
      keyType: KeyType.p256,
    );
    await didManager.addVerificationMethod(keyId);
    return TestParty(didManager, keyPair, await didManager.getDidDocument());
  }

  Future<Map<String, dynamic>> authcrypt(
    PlainTextMessage message, {
    required TestParty to,
  }) async {
    final encrypted = await DidcommMessage.packIntoEncryptedMessage(
      message,
      keyPair: keyPair,
      didKeyId: didDocument.keyAgreement.first.id,
      recipientDidDocuments: [to.didDocument],
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    );
    return encrypted.toJson();
  }
}
