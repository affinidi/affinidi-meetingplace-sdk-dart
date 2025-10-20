import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final oobUrlBytes = File('./oob-url.txt').readAsBytesSync();

  final oobUri = Uri.parse(utf8.decode(oobUrlBytes));
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final bobWaitFor = Completer<Channel>();

  // Bob accepts OOB
  final acceptance = await bobSDK.acceptOobFlow(
    oobUri,
    vCard: VCard(values: {'firstName': 'Bob'}),
  );

  // Bob listens for approval
  prettyPrintYellow('Listening on OOB stream...');
  acceptance.stream.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    bobWaitFor.complete(data.channel);
  }).timeout(
    const Duration(seconds: 300),
    () => prettyPrint('OOB stream timeout'),
  );

  final channel = await bobWaitFor.future;
  prettyJsonPrintYellow('Received channel', channel.toJson());

  // Close stream
  prettyPrint('Disposing OOB stream...');
  await acceptance.stream.dispose();
}
