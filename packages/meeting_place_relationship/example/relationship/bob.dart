// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

Future<void> main() async {
  // ── 1. Initialise both SDKs ────────────────────────────────────────────
  prettyPrintGreen('>>> Initialising SDK bundle for Bob');
  final (coreSDK, relationshipSDK) = await initSDKBundle(
    wallet: PersistentWallet(InMemoryKeyStore()),
  );

  // ── 2. Register for DIDComm notifications ──────────────────────────────
  prettyPrintGreen('>>> Registering for DIDComm notifications');
  final notification = await coreSDK.registerForDIDCommNotifications();
  final notificationDid = (await notification.recipientDid.getDidDocument()).id;
  prettyPrintYellow('Notification DID: $notificationDid');

  // ── 3. Set up relationship stream listeners ────────────────────────────
  late Channel bobChannel;
  final rCardCompleter = Completer<RCard>();
  final vrcCompleter = Completer<VrcIssuance>();

  relationshipSDK.receivedRCards.listen((rCard) {
    prettyPrintYellow("Alice's R-Card received from ${rCard.subjectDid}");
    if (!rCardCompleter.isCompleted) rCardCompleter.complete(rCard);
  });

  relationshipSDK.receivedVrcRequests.listen((request) async {
    // Alice has requested VRC exchange. Bob responds by sending his VRC.
    // bobChannel is assigned before any VDIP message can arrive.
    prettyPrintYellow(
      'VRC request received from ${request.senderDid} - sending VRC',
    );
    await relationshipSDK.sendVrc(
      channelDid: bobChannel.otherPartyPermanentChannelDid!,
      issuerDid: bobChannel.permanentChannelDid!,
      issuerName: 'Bob',
      peerDid: bobChannel.otherPartyPermanentChannelDid!,
      peerName: 'Alice',
    );
    prettyPrintYellow('Bob VRC sent to Alice.');
  });

  relationshipSDK.receivedVrcs.listen((issuance) {
    prettyPrintYellow("Alice's VRC received from ${issuance.senderDid}");
    if (!vrcCompleter.isCompleted) vrcCompleter.complete(issuance);
  });

  // ── 4. Read mnemonic written by Alice ──────────────────────────────────
  const mnemonicFile = '.example-output/relationship-storage.txt';
  prettyPrint('Reading mnemonic from $mnemonicFile ...');
  final mnemonic = File(mnemonicFile).readAsStringSync().trim();

  // ── 5. Control plane event listener ────────────────────────────────────
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  coreSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised &&
        !waitForOfferFinalised.isCompleted) {
      waitForOfferFinalised.complete(event);
    }
  });

  // ── 6. Subscribe to mediator (notification DID for initial handshake) ──
  prettyPrintGreen('>>> Subscribing to mediator');
  final notificationStream = await coreSDK.subscribeToMediator(notificationDid);
  notificationStream.stream.listen((data) async {
    prettyJsonPrintYellow('Notification', data.plainTextMessage.toJson());
    await coreSDK.processControlPlaneEvents();
  });

  // ── 7. Accept Alice's offer ────────────────────────────────────────────
  prettyPrintGreen(">>> Accepting Alice's offer");
  final findOfferResult = await coreSDK.findOffer(mnemonic: mnemonic);
  await coreSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    contactCard: ContactCard(
      did: 'did:example:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );
  prettyPrintYellow('Offer accepted - waiting for Alice to approve...');

  final channelEvent = await waitForOfferFinalised.future;
  bobChannel = channelEvent.channel;

  prettyPrintYellow('Bob channel DID   : ${bobChannel.permanentChannelDid}');
  prettyPrintYellow(
    'Alice channel DID : ${bobChannel.otherPartyPermanentChannelDid}',
  );

  // Switch from notification DID to permanentChannelDid — same pattern as
  // Chat SDK: dispose the handshake stream, subscribe to the channel inbox.
  await notificationStream.dispose();
  prettyPrintGreen('>>> Subscribing to channel DID for VDIP messages');
  final channelStream = await coreSDK.subscribeToMediator(
    bobChannel.permanentChannelDid!,
  );
  channelStream.stream.listen((data) async {
    prettyJsonPrintYellow('Channel message', data.plainTextMessage.toJson());
    await coreSDK.processControlPlaneEvents();
  });
  // Fetch any events already queued before we subscribed.
  await coreSDK.processControlPlaneEvents();

  // ── 8. Send Bob's R-Card to Alice ──────────────────────────────────────
  prettyPrintGreen(">>> Sending Bob's R-Card to Alice");
  final bobDidManager = await coreSDK.getDidManager(
    bobChannel.permanentChannelDid!,
  );

  const bobCard = RCardSubject(
    firstName: 'Bob',
    lastName: 'Jones',
    email: 'bob@example.com',
    phone: '+1-555-0200',
    company: 'Affinidi',
    position: 'Engineer',
    website: 'https://bob.example.com',
  );

  await relationshipSDK.sendRCard(
    channel: bobChannel,
    subjectDid: bobChannel.otherPartyPermanentChannelDid!,
    card: bobCard,
    issuerDidManager: bobDidManager,
  );
  prettyPrintYellow("Bob's R-Card sent.");

  // ── 9. Wait for Alice's VRC and Bob's response to complete ─────────────
  prettyPrintYellow("=== Waiting for Alice's VRC exchange request...");
  await vrcCompleter.future;

  // ── 10. Optionally wait for Alice's R-Card ─────────────────────────────
  if (!rCardCompleter.isCompleted) {
    prettyPrintYellow("=== Waiting for Alice's R-Card...");
    await rCardCompleter.future;
  }

  // ── 11. Clean up ──────────────────────────────────────────────────────
  await channelStream.dispose();
  await relationshipSDK.closeRelationshipStreams();

  final storedRCards = await relationshipSDK.listReceivedRCards();
  final storedVrcs = await relationshipSDK.listVrcs();
  prettyPrint('\n=== Exchange complete ===');
  prettyPrintYellow('R-Cards stored : ${storedRCards.length}');
  prettyPrintYellow('VRCs stored    : ${storedVrcs.length}');
  prettyPrint('Both parties now hold mutual VRCs and each other\'s R-Cards.');
}
