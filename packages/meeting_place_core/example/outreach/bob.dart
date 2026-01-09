import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Bob registers for DIDComm notifications
  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await bobSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.outreachInvitation,
  );

  final file = File('./storage.txt');
  file.writeAsBytesSync(
      utf8.encode(publishOfferResult.connectionOffer.mnemonic));

  prettyJsonPrintYellow(
      'Connection offer', publishOfferResult.connectionOffer.toJson());

  // Listen on control plane events stream to wait for outreach invitation
  prettyPrintYellow('Listen on new events...');
  final waitForOutreachInvitation = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationOutreach) {
      waitForOutreachInvitation.complete(event);
    }
  });

  // Listen to mediator stream using notification DID
  prettyPrintGreen('>>> Calling SDK.subscribeToMediator.listen');
  final notificationStream =
      await bobSDK.subscribeToMediator(notificationDidDocument.id);

  prettyPrintYellow('>>> Listen on notification stream');
  notificationStream.stream.listen((data) async {
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Alice to send outrach invitation');

  final receivedEvent = await waitForOutreachInvitation.future;
  prettyPrintYellow('Received invitation outreach event');
  prettyJsonPrintYellow('Event channel', receivedEvent.channel.toJson());

  await notificationStream.dispose();
}
