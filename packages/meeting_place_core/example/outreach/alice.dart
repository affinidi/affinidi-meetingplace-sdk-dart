import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  // Alice publishes offer
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Alice registers for DIDComm notifications
  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await aliceSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  // Alice publishes offer
  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      senderInfo: 'Alice',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  prettyJsonPrintYellow(
    'Connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  // Alice listens on control plane events stream to wait for invitation accept
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }
  });

  // Alice listens to mediator stream using notification DID
  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final notificationStream =
      await aliceSDK.subscribeToMediator(notificationDidDocument.id);

  prettyPrintYellow('>>> Listen on notification stream');
  notificationStream.stream
      .where((data) => data.plainTextMessage.type
          .toString()
          .startsWith(getControlPlaneDid()))
      .listen((data) async {
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await aliceSDK.processControlPlaneEvents();
  });

  final file = File('./storage.txt');
  final mnemonicBytes = file.readAsBytesSync();

  prettyPrintGreen('>>> Calling SDK.findOffer');
  final findOfferResult = await aliceSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );

  if (findOfferResult.connectionOffer == null) {
    throw Exception('Run bob.dart first');
  }

  prettyJsonPrintYellow(
    'Offer details',
    findOfferResult.connectionOffer!.toJson(),
  );

  // Alice sends outreach invitation to Bob
  prettyPrintGreen('>>> Calling SDK.sendOutreachInvitation');
  await aliceSDK.sendOutreachInvitation(
    outreachConnectionOffer: findOfferResult.connectionOffer!,
    inviteToConnectionOffer: publishOfferResult.connectionOffer,
    messageToInclude: 'Please connect to my offer',
    senderInfo: 'Alice',
  );

  prettyPrintYellow('=== Waiting for Bob to accept offer');
  final receivedEvent = await waitForInvitationAccept.future;

  prettyJsonPrintYellow(
    'InvitationAccept event channel',
    receivedEvent.channel.toJson(),
  );

  await notificationStream.dispose();
}
