import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final aliceWaitFor = Completer<void>();

  // Alice creates OOB
  prettyPrintGreen('>>> Calling SDK.createOobFlow');
  final oob = await aliceSDK.createOobFlow(
    vCard: VCard(values: {'firstName': 'Alice'}),
  );

  prettyPrintYellow('OOB URL: ${oob.oobUrl.toString()}');
  File('./oob-url.txt').writeAsBytesSync(utf8.encode(oob.oobUrl.toString()));

  // Alice listens on acceptance
  prettyPrintYellow('Listening on OOB stream...');
  oob.stream.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message:', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    aliceWaitFor.complete();
  }).timeout(
    const Duration(seconds: 300),
    () => prettyPrint('OOB stream timeout'),
  );

  await aliceWaitFor.future;

  // Close stream
  prettyPrint('Disposing OOB stream...');
  await oob.stream.dispose();
}
