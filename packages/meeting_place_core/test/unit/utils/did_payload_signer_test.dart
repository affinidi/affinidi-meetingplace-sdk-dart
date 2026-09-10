import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockDidResolver extends Mock implements DidResolver {}

Future<DidManager> _newDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final key = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(key.id);
  return didManager;
}

void main() {
  const signer = DidPayloadSigner();
  late DidManager signerDidManager;
  late String signerDid;
  late String signerVerificationMethodId;
  late _MockDidResolver didResolver;

  setUp(() async {
    signerDidManager = await _newDidManager();
    final didDocument = await signerDidManager.getDidDocument();
    signerDid = didDocument.id;
    signerVerificationMethodId =
        didDocument.authentication.first.id.startsWith('#')
        ? '$signerDid${didDocument.authentication.first.id}'
        : didDocument.authentication.first.id;

    didResolver = _MockDidResolver();
    when(
      () => didResolver.resolveDid(signerDid),
    ).thenAnswer((_) async => didDocument);
  });

  group('DidPayloadSigner', () {
    test('verifies a payload signed by the claimed signer', () async {
      final payload = {'callId': 'room@1', 'endedAt': 1000};

      final jws = await signer.sign(
        payload: payload,
        didManager: signerDidManager,
        verificationMethodId: signerVerificationMethodId,
      );

      final verified = await signer.verify(
        jws: jws,
        expectedSignerDid: signerDid,
        didResolver: didResolver,
      );

      expect(verified, payload);
    });

    test('rejects a payload signed by a different DID', () async {
      final otherDidManager = await _newDidManager();
      final otherDidDocument = await otherDidManager.getDidDocument();
      final otherAuthId = otherDidDocument.authentication.first.id;
      final otherVerificationMethodId = otherAuthId.startsWith('#')
          ? '${otherDidDocument.id}$otherAuthId'
          : otherAuthId;

      final jws = await signer.sign(
        payload: {'callId': 'room@1'},
        didManager: otherDidManager,
        verificationMethodId: otherVerificationMethodId,
      );

      final verified = await signer.verify(
        jws: jws,
        expectedSignerDid: signerDid,
        didResolver: didResolver,
      );

      expect(verified, isNull);
    });

    test('rejects a tampered payload', () async {
      final jws = await signer.sign(
        payload: {'callId': 'room@1', 'endedAt': 1000},
        didManager: signerDidManager,
        verificationMethodId: signerVerificationMethodId,
      );

      final parts = jws.split('.');
      final tampered = '${parts[0]}.tampered.${parts[2]}';

      final verified = await signer.verify(
        jws: tampered,
        expectedSignerDid: signerDid,
        didResolver: didResolver,
      );

      expect(verified, isNull);
    });

    test('rejects a malformed JWS', () async {
      final verified = await signer.verify(
        jws: 'not-a-jws',
        expectedSignerDid: signerDid,
        didResolver: didResolver,
      );

      expect(verified, isNull);
    });
  });
}
