import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  // Alice publishes offer
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  await aliceSDK.registerForPushNotifications(const Uuid().v4());

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    vCard: VCard(values: {}),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  prettyJsonPrintYellow(
    'Connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }
  });

  final publishOfferMediatorChannel = await aliceSDK.subscribeToMediator(
    publishOfferResult.connectionOffer.publishOfferDid,
    deleteOnMediator: false,
  );

  publishOfferMediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.connectionSetup.value) {
      prettyPrintYellow('Received connection setup message');
      prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
      await aliceSDK.processControlPlaneEvents();
    }
  });

  prettyPrintGreen('>>> Calling SDK.findOffer');
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
}
