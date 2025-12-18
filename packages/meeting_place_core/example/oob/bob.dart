import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final oobUrlBytes = File('./oob-url.txt').readAsBytesSync();

  final oobUri = Uri.parse(utf8.decode(oobUrlBytes));
  prettyPrintYellow('OOB uri: ${oobUri.toString()}');
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final bobWaitFor = Completer<Channel>();

  // Bob accepts OOB
  final acceptance = await bobSDK.acceptOobFlow(
    oobUri,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      senderInfo: 'Bob',
      contactInfo: {'firstName': 'Bob'},
    ),
  );

  // Bob listens for approval
  prettyPrintYellow('Listening on OOB stream...');
  acceptance.streamSubscription.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    bobWaitFor.complete(data.channel);
  });

  acceptance.streamSubscription.timeout(
    const Duration(seconds: 300),
    () => prettyPrint('OOB stream timeout'),
  );

  final channel = await bobWaitFor.future;
  prettyJsonPrintYellow('Received channel', channel.toJson());

  // Close stream
  prettyPrint('Disposing OOB stream...');
  await acceptance.streamSubscription.dispose();

  await bobSDK.sendMessage(
      PlainTextMessage(
          id: Uuid().v4(),
          type: Uri.parse('https://affinidi.io/meeting-place-core/example/oob'),
          from: channel.permanentChannelDid,
          to: [channel.otherPartyPermanentChannelDid!],
          body: {'hello': 'world'}),
      senderDid: channel.permanentChannelDid!,
      recipientDid: channel.otherPartyPermanentChannelDid!);

  prettyPrint('Message sent to Alice');
}
