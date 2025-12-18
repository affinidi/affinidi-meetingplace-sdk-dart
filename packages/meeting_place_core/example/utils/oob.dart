import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'print.dart';
import 'sdk.dart';

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final aliceWaitFor = Completer<void>();
  final bobWaitFor = Completer<void>();

  // Alice creates OOB
  final oob = await aliceSDK.createOobFlow(
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      senderInfo: 'Alice',
      contactInfo: {'firstName': 'Alice'},
    ),
  );

  // Alice listens on acceptance
  oob.streamSubscription.listen((data) {
    prettyPrint('Alice received: ${data.eventType.name}');
    aliceWaitFor.complete();
  });

  // Bob accepts OOB
  final acceptance = await bobSDK.acceptOobFlow(
    oob.oobUrl,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      senderInfo: 'Bob',
      contactInfo: {'firstName': 'Bob'},
    ),
  );

  // Bob listens for approval
  acceptance.streamSubscription.listen((data) {
    prettyPrint('Bob received: ${data.eventType.name}');
    bobWaitFor.complete();
  });

  await Future.wait([aliceWaitFor.future, bobWaitFor.future]);

  // Close stream
  await oob.streamSubscription.dispose();
  await acceptance.streamSubscription.dispose();
}
