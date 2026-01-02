import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
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
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {'firstName': 'Alice'},
    ),
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

  prettyPrintGreen('>>> Calling SDK.requestCredential on channel');
  await Future.delayed(const Duration(seconds: 10));

  final holderDidManager = await aliceSDK.generateDid();
  final holderDidDoc = await holderDidManager.getDidDocument();

  final credentialResponse = await aliceSDK.vdip.requestCredential(
    holderDidDoc.id,
    channel: channel,
    options: RequestCredentialsOptions(
      proposalId: 'will-be-optional-in-future',
      credentialMeta: CredentialMeta(data: {'persona_did': 'did:key:123'}),
    ),
  );

  prettyJsonPrintYellow(
      'Received credential response:', credentialResponse.credential);
}
