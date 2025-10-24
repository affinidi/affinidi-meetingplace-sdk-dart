import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/core/mediator/mediator_exception.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixture/sdk_fixture.dart';

void main() async {
  final aliceWallet = PersistentWallet(InMemoryKeyStore());

  final mediatorSDK = MeetingPlaceMediatorSDK(
    mediatorDid: getMediatorDid(),
    didResolver: UniversalDIDResolver.defaultResolver,
  );

  test('throws error if ACL updates fails', () async {
    final keyPair = await aliceWallet.generateKey();
    final ownerDidManager = DidKeyManager(
      wallet: aliceWallet,
      store: InMemoryDidStore(),
    );

    await ownerDidManager.addVerificationMethod(keyPair.id);

    expect(
      () => mediatorSDK.updateAcl(
        ownerDidManager: ownerDidManager,
        acl: AccessListAdd(
          ownerDid: 'did:key:invalid',
          granteeDids: ['did:key:1234'],
        ),
      ),
      throwsA(
        predicate(
          (e) =>
              e is MeetingPlaceMediatorSDKException &&
              e.toString().contains('An error while calling mediator'),
        ),
      ),
    );
  });

  test('throws error if susbcription to mediator fails', () async {
    final keyPair = await aliceWallet.generateKey();
    final didManager = DidKeyManager(
      wallet: aliceWallet,
      store: InMemoryDidStore(),
    );

    await didManager.addVerificationMethod(keyPair.id);

    expect(
      () => mediatorSDK.subscribeToMessages(
        didManager,
        mediatorDid: 'did:web:invalid',
      ),
      throwsA(
        predicate(
          (e) =>
              e is MeetingPlaceMediatorSDKException &&
              e.code ==
                  MeetingPlaceMediatorSDKErrorCode
                      .subscribeToWebsocketError.value,
        ),
      ),
    );
  });

  test('throws error if sending message to mediator fails', () async {
    final keyPair = await aliceWallet.generateKey();
    final didManager = DidKeyManager(
      wallet: aliceWallet,
      store: InMemoryDidStore(),
    );

    await didManager.addVerificationMethod(keyPair.id);

    final recipientKeyPair =
        await aliceWallet.generateKey(keyType: KeyType.secp256k1);
    final recipientDidManager = DidKeyManager(
      wallet: aliceWallet,
      store: InMemoryDidStore(),
    );

    await recipientDidManager.addVerificationMethod(recipientKeyPair.id);
    final didDocument = await recipientDidManager.getDidDocument();

    expect(
      () => mediatorSDK.sendMessage(
        PlainTextMessage(
          id: Uuid().v4(),
          type: Uri.parse('https://example.com/type/test-message'),
        ),
        senderDidManager: didManager,
        recipientDidDocument: didDocument,
      ),
      throwsA(
        predicate(
          (e) =>
              e is MeetingPlaceMediatorSDKException &&
              e.innerException is MediatorException &&
              (e.innerException as MediatorException).message ==
                  'Mediator Error: key agreement match not found',
        ),
      ),
    );
  });
}
