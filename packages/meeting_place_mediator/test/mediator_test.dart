import 'dart:io';

import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/sdk/mediator_sdk_options.dart';
import 'package:test/test.dart';
import 'package:ssi/ssi.dart';

import 'fixture/sdk_fixture.dart';

void main() {
  late MediatorSDK sdk;
  late DidManager didManagerA;
  late DidManager didManagerB;

  setUp(() async {
    final aliceWallet = PersistentWallet(InMemoryKeyStore());
    sdk = MediatorSDK(
      mediatorDid: getMediatorDid(),
      didResolver: UniversalDIDResolver(),
    );

    final keyPairA = await aliceWallet.generateKey(keyId: "m/44'/60'/0'/1");
    didManagerA = DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());

    await didManagerA.addVerificationMethod(keyPairA.id);

    final keyPairB = await aliceWallet.generateKey(keyId: "m/44'/60'/0'/2");
    didManagerB = DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());

    await didManagerB.addVerificationMethod(keyPairB.id);
  });

  test(
    'Reuses cached mediator session when already initialized for did',
    () async {
      final sessionA = await sdk.authenticateWithDid(didManagerA);
      final sessionB = await sdk.authenticateWithDid(didManagerA);
      expect(sessionA.session, equals(sessionB.session));
    },
  );

  test('Uses new mediator session if did is not cached', () async {
    final sessionA = await sdk.authenticateWithDid(didManagerA);
    final sessionB = await sdk.authenticateWithDid(didManagerB);
    expect(sessionA, isNot(equals(sessionB)));
  });

  test('Uses new mediator session if mediator did changes', () async {
    final sessionA = await sdk.authenticateWithDid(didManagerA);
    sdk.mediatorDid = Platform.environment['MEDIATOR_DID_ALTERNATIVE'] ??
        (throw Exception('MEDIATOR_DID_ALTERNATIVE not set in environment'));

    final sessionB = await sdk.authenticateWithDid(didManagerA);
    expect(sessionA, isNot(equals(sessionB)));
  });

  test('Update ACL to publish', () async {
    final didDoc = await didManagerA.getDidDocument();
    await sdk.updateAcl(
      ownerDidManager: didManagerA,
      acl: AclSet.toPublic(ownerDid: didDoc.id),
    );
  });

  test('Reauthenticates if access token is about to expire', () async {
    final mySDK = MediatorSDK(
      mediatorDid: getMediatorDid(),
      didResolver: UniversalDIDResolver(),
      options: MediatorSDKOptions(secondsBeforeExpiryReauthenticate: 15 * 60),
    );

    final sessionA = await mySDK.authenticateWithDid(didManagerA);
    final accessTokenA = sessionA.session!.accessToken;

    final sessionB = await mySDK.authenticateWithDid(didManagerA);
    final accessTokenB = sessionB.session!.accessToken;

    expect(accessTokenA, isNot(equals(accessTokenB)));
  });
}
