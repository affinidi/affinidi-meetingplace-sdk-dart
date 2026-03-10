import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixture/sdk_fixture.dart';

void main() {
  late MeetingPlaceMediatorSDK sdk;
  late DidManager didManager;

  setUpAll(() async {
    final aliceWallet = PersistentWallet(InMemoryKeyStore());
    sdk = MeetingPlaceMediatorSDK(
      mediatorDid: getMediatorDid(),
      didResolver: UniversalDIDResolver(),
    );

    final keyPairA = await aliceWallet.generateKey();
    didManager = DidKeyManager(wallet: aliceWallet, store: InMemoryDidStore());

    await didManager.addVerificationMethod(keyPairA.id);
  });

  test('Mediator SDK returns OOB url', () async {
    final oob = await sdk.createOob(didManager, getMediatorDid());
    expect(oob.hasAbsolutePath, equals(true));
  });

  test('Mediator SDK returns OOB details', () async {
    final expDid = await didManager.getDidDocument();
    final oob = await sdk.createOob(didManager, getMediatorDid());
    final invitationMessage = await sdk.getOob(oob);

    expect(invitationMessage?.from, equals(expDid.id));
    expect(invitationMessage?.body?['goal_code'], equals('connect'));
    expect(invitationMessage?.body?['goal'], equals('Start relationship'));
    expect(invitationMessage?.body?['accept'], equals(['didcomm/v2']));
  });

  test('Mediator SDK returns null if oob is not found', () async {
    final oob = await sdk.createOob(didManager, getMediatorDid());
    final invitationMessage = await sdk.getOob(Uri.parse('$oob-not-found'));
    expect(invitationMessage, isNull);
  });
}
