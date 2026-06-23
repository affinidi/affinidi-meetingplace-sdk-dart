import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final aliceWaitFor = Completer<Channel>();

  // Alice creates OOB
  prettyPrintGreen('>>> Calling SDK.createOobFlow');
  final oob = await aliceSDK.createOobFlow(
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {'firstName': 'Alice'},
    ),
  );

  prettyPrintYellow('OOB URL: ${oob.oobUrl.toString()}');
  final outputDirectory = Directory('.example-output')
    ..createSync(recursive: true);
  File(
    '${outputDirectory.path}${Platform.pathSeparator}oob-url.txt',
  ).writeAsBytesSync(utf8.encode(oob.oobUrl.toString()));

  // Alice listens on acceptance
  prettyPrintYellow('Listening on OOB stream...');
  oob.stream.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message:', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    aliceWaitFor.complete(data.channel);
  });

  final channel = await aliceWaitFor.future;

  // Close stream
  prettyPrint('Disposing OOB stream...');
  await oob.stream.dispose();

  final messageStream = await aliceSDK.subscribe(
    DidCommSubscription(receiverDid: channel.permanentChannelDid!),
  );

  final waitForBobsMessage = Completer<PlainTextMessage>();
  final messageSubscription = messageStream.stream.listen((
    IncomingMessage message,
  ) {
    final didcommMessage = message as DidCommIncomingMessage;
    if (didcommMessage.payload.isOfType(
      'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/example',
    )) {
      waitForBobsMessage.complete(didcommMessage.payload);
    }
  });

  prettyPrintYellow('Waiting for Bob\'s message...');
  prettyJsonPrintYellow(
    'Received Bob\'s message',
    (await waitForBobsMessage.future).toJson(),
  );

  // Close stream
  prettyPrint('Disposing message stream...');
  await messageSubscription.cancel();
}
