import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../fixture/sdk_fixture.dart';

class MediatorIntegrationFixture {
  MediatorIntegrationFixture._();

  late final MeetingPlaceMediatorSDK sdk;
  late final DidManager didManagerA;
  late final DidManager didManagerB;
  late final DidManager didManagerC;

  static Future<MediatorIntegrationFixture> create() async {
    final fixture = MediatorIntegrationFixture._();

    final wallet = PersistentWallet(InMemoryKeyStore());
    fixture.sdk = MeetingPlaceMediatorSDK(
      mediatorDid: getMediatorDid(),
      didResolver: UniversalDIDResolver(),
    );

    final keyPairA = await wallet.generateKey();
    final didManagerA =
        DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManagerA.addVerificationMethod(keyPairA.id);
    fixture.didManagerA = didManagerA;

    final keyPairB = await wallet.generateKey();
    final didManagerB =
        DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManagerB.addVerificationMethod(keyPairB.id);
    fixture.didManagerB = didManagerB;

    final keyPairC = await wallet.generateKey();
    final didManagerC =
        DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    await didManagerC.addVerificationMethod(keyPairC.id);
    fixture.didManagerC = didManagerC;

    return fixture;
  }
}
