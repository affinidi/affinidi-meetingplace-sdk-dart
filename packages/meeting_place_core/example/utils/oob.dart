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
    vCard: VCard(values: {'firstName': 'Alice'}),
  );

  // Alice listens on acceptance
  oob.stream.listen((data) {
    prettyPrint('Alice received: ${data.eventType.name}');
    aliceWaitFor.complete();
  });

  // Bob accepts OOB
  final acceptance = await bobSDK.acceptOobFlow(oob.oobUrl,
      vCard: VCard(values: {'firstName': 'Bob'}));

  // Bob listens for approval
  acceptance.stream.listen((data) {
    prettyPrint('Bob received: ${data.eventType.name}');
    bobWaitFor.complete();
  });

  await Future.wait([aliceWaitFor.future, bobWaitFor.future]);

  // Close stream
  await oob.stream.dispose();
  await acceptance.stream.dispose();
}
