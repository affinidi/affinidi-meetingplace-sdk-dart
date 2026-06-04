// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

Future<void> main() async {
  // ── 1. Initialise both SDKs ────────────────────────────────────────────
  prettyPrintGreen('>>> Initialising SDK bundle for Alice');
  final (coreSDK, credentialsSDK) = await initSDKBundle(
    wallet: PersistentWallet(InMemoryKeyStore()),
  );

  // ── 2. Register for DIDComm notifications ──────────────────────────────
  prettyPrintGreen('>>> Registering for DIDComm notifications');
  final notification = await coreSDK.registerForDIDCommNotifications();
  final notificationDid = (await notification.recipientDid.getDidDocument()).id;
  prettyPrintYellow('Notification DID: $notificationDid');

  // ── 3. Set up credentials stream listeners ────────────────────────────
  // These streams are fed by VDIP messages that arrive via channel activity
  // events - processControlPlaneEvents() (called in the mediator listener
  // below) is what triggers the VDIP message fetch.
  late Channel aliceChannel;
  final rCardCompleter = Completer<RCard>();
  final vrcCompleter = Completer<VrcIssuance>();

  credentialsSDK.receivedRCards.listen((rCard) {
    prettyPrintYellow('R-Card received from ${rCard.subjectDid}');
    if (!rCardCompleter.isCompleted) rCardCompleter.complete(rCard);
  });

  credentialsSDK.receivedVrcRequests.listen((_) {
    // Alice initiates the VRC exchange, so she does not expect a request.
    prettyPrintYellow('VRC request received (unexpected on Alice side)');
  });

  credentialsSDK.receivedVrcs.listen((issuance) async {
    // Bob has sent his VRC. Alice reciprocates immediately.
    // aliceChannel is assigned before any VDIP message can arrive.
    prettyPrintYellow(
      'VRC received from ${issuance.senderDid} - reciprocating',
    );
    await credentialsSDK.sendVrc(
      channelDid: aliceChannel.otherPartyPermanentChannelDid!,
      issuerDid: aliceChannel.permanentChannelDid!,
      issuerName: 'Alice',
      peerDid: aliceChannel.otherPartyPermanentChannelDid!,
      peerName: 'Bob',
    );
    prettyPrintYellow('Alice VRC sent to Bob.');
    if (!vrcCompleter.isCompleted) vrcCompleter.complete(issuance);
  });

  // ── 4. Publish connection offer ────────────────────────────────────────
  prettyPrintGreen('>>> Publishing connection offer');
  final offerResult = await coreSDK.publishOffer(
    offerName: 'Relationship example',
    offerDescription: 'Connect to exchange R-Cards and VRCs.',
    contactCard: ContactCard(
      did: 'did:example:alice',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 10)),
  );

  final outputDir = Directory('.example-output')..createSync(recursive: true);
  File(
    '${outputDir.path}/credentials-storage.txt',
  ).writeAsStringSync(offerResult.connectionOffer.mnemonic);
  prettyJsonPrintYellow(
    'Connection offer',
    offerResult.connectionOffer.toJson(),
  );
  prettyPrintYellow(
    'Mnemonic written → .example-output/credentials-storage.txt',
  );
  prettyPrint('Run credentials/bob.dart now in a separate terminal.');

  // ── 5. Control plane event listener ────────────────────────────────────
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  coreSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept &&
        !waitForInvitationAccept.isCompleted) {
      waitForInvitationAccept.complete(event);
    }
    if (event.type == ControlPlaneEventType.ChannelActivity &&
        !waitForChannelActivity.isCompleted) {
      waitForChannelActivity.complete(event);
    }
  });

  // ── 6. Subscribe to mediator (notification DID for initial handshake) ──
  // Mirrors the Chat SDK pattern: use the notification DID subscription only
  // until the permanent channel is established, then switch to the channel DID.
  prettyPrintGreen('>>> Subscribing to mediator');
  final notificationStream = await coreSDK.subscribeToMediator(notificationDid);
  notificationStream.stream.listen((data) async {
    prettyJsonPrintYellow('Notification', data.plainTextMessage.toJson());
    await coreSDK.processControlPlaneEvents();
  });

  // ── 7. Wait for Bob to accept ──────────────────────────────────────────
  prettyPrintYellow('=== Waiting for Bob to accept the offer...');
  final invitationEvent = await waitForInvitationAccept.future;

  prettyPrintGreen('>>> Bob accepted - approving connection request');
  aliceChannel = await coreSDK.approveConnectionRequest(
    channel: invitationEvent.channel,
  );
  prettyPrintYellow('Alice channel DID : ${aliceChannel.permanentChannelDid}');
  prettyPrintYellow(
    'Bob channel DID   : ${aliceChannel.otherPartyPermanentChannelDid}',
  );

  // ── 8. Wait for channel inauguration ──────────────────────────────────
  // Bob sends the channel inauguration message after accepting the offer.
  // VDIP sends will fail until this ChannelActivity event is received.
  prettyPrintYellow(
    '=== Waiting for Bob to send channel inauguration'
    ' message...',
  );
  await waitForChannelActivity.future;
  prettyPrintYellow('Channel activity received - channel is live.');

  // Switch from notification DID to permanentChannelDid — same pattern as
  // Chat SDK: dispose the handshake stream, subscribe to the channel inbox
  // so VDIP messages stored there are delivered directly.
  await notificationStream.dispose();
  prettyPrintGreen('>>> Subscribing to channel DID for VDIP messages');
  final channelStream = await coreSDK.subscribeToMediator(
    aliceChannel.permanentChannelDid!,
  );
  channelStream.stream.listen((data) async {
    prettyJsonPrintYellow('Channel message', data.plainTextMessage.toJson());
    await coreSDK.processControlPlaneEvents();
  });
  // Fetch any events already queued before we subscribed.
  await coreSDK.processControlPlaneEvents();

  // ── 9. Send Alice's R-Card to Bob ──────────────────────────────────────
  prettyPrintGreen(">>> Sending Alice's R-Card to Bob");
  final aliceDidManager = await coreSDK.getDidManager(
    aliceChannel.permanentChannelDid!,
  );

  const aliceCard = RCardSubject(
    firstName: 'Alice',
    lastName: 'Smith',
    email: 'alice@example.com',
    phone: '+1-555-0100',
    company: 'Affinidi',
    position: 'Engineer',
    website: 'https://alice.example.com',
  );

  await credentialsSDK.sendRCard(
    channel: aliceChannel,
    subjectDid: aliceChannel.otherPartyPermanentChannelDid!,
    card: aliceCard,
    issuerDidManager: aliceDidManager,
  );
  prettyPrintYellow("Alice's R-Card sent.");

  // Small pause so Bob processes the R-Card event in its own batch before
  // the VRC request arrives - prevents both ChannelActivity events from
  // landing in the same processControlPlaneEvents() batch.
  await Future<void>.delayed(const Duration(seconds: 1));

  // ── 10. Initiate VRC exchange ───────────────────────────────────────────
  // channelDid = Bob's permanentChannelDid (used for VDIP routing).
  // identityDid = the DID embedded in the VRC from-party (Alice's channel DID
  // here; in production use a stable long-lived identity DID).
  prettyPrintGreen('>>> Requesting VRC exchange with Bob');
  await credentialsSDK.requestVrcExchange(
    channelDid: aliceChannel.otherPartyPermanentChannelDid!,
    identityDid: aliceChannel.permanentChannelDid!,
    identityName: 'Alice',
  );
  prettyPrintYellow('VRC exchange requested - waiting for Bob to respond...');

  // ── 11. Wait for Bob's VRC and Alice's reciprocation to complete ───────
  await vrcCompleter.future;

  // ── 12. Optionally wait for Bob's R-Card too ───────────────────────────────
  if (!rCardCompleter.isCompleted) {
    prettyPrintYellow('=== Waiting for Bob\'s R-Card...');
    await rCardCompleter.future;
  }

  // ── 13. Clean up ───────────────────────────────────────────────────────────
  await channelStream.dispose();
  await credentialsSDK.closeCredentialStreams();

  final storedRCards = await credentialsSDK.listReceivedRCards();
  final storedVrcs = await credentialsSDK.listVrcs();
  prettyPrint('\n=== Exchange complete ===');
  prettyPrintYellow('R-Cards stored : ${storedRCards.length}');
  prettyPrintYellow('VRCs stored    : ${storedVrcs.length}');
  prettyPrint('Both parties now hold mutual VRCs and each other\'s R-Cards.');
}
