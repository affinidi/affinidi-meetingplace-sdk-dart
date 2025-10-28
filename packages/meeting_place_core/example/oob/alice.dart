import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final aliceWaitFor = Completer<Channel>();

  // Alice creates OOB
  prettyPrintGreen('>>> Calling SDK.createOobFlow');
  final oob = await aliceSDK.createOobFlow(
    vCard: VCard(values: {'firstName': 'Alice'}),
  );

  prettyPrintYellow('OOB URL: ${oob.oobUrl.toString()}');
  File('./oob-url.txt').writeAsBytesSync(utf8.encode(oob.oobUrl.toString()));

  // Alice listens on acceptance
  prettyPrintYellow('Listening on OOB stream...');
  oob.streamSubscription.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message:', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    aliceWaitFor.complete(data.channel);
  });

  final channel = await aliceWaitFor.future;

  // Close stream
  prettyPrint('Disposing OOB stream...');
  await oob.streamSubscription.dispose();

  final messageSubscription = await aliceSDK.subscribeToMediator(
    channel.permanentChannelDid!,
  );

  final waitForBobsMessage = Completer<PlainTextMessage>();
  messageSubscription.stream.listen((message) {
    if (message.plainTextMessage
        .isOfType('https://affinidi.io/meeting-place-core/example/oob')) {
      waitForBobsMessage.complete(message.plainTextMessage);
    }
  });

  prettyPrintYellow('Waiting for Bob\'s message...');
  prettyJsonPrintYellow(
      'Received Bob\'s message', (await waitForBobsMessage.future).toJson());

  // Close stream
  prettyPrint('Disposing message stream...');
  await messageSubscription.dispose();
}
