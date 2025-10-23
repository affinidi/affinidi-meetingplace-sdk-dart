import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  // Bob approves offer
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Bob registers for DIDComm notifications
  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  final file = File('./storage.txt');
  final mnemonicBytes = file.readAsBytesSync();

  prettyPrintGreen('>>> Calling SDK.findOffer');
  final findOfferResult = await bobSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );
  prettyJsonPrintYellow(
    'Offer details',
    findOfferResult.connectionOffer!.toJson(),
  );

  prettyPrintGreen('>>> Calling SDK.acceptOffer');
  final acceptOfferResult = await bobSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    vCard: VCard(values: {}),
  );

  prettyJsonPrintYellow(
    'Acceptance details',
    acceptOfferResult.connectionOffer.toJson(),
  );

  // Listen on control plane events stream to receive updates about
  // published offer
  prettyPrint('Listen on new events...');
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  // Listen to mediator stream using notification DID
  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final notificationStream =
      await bobSDK.subscribeToMediator(notificationDidDocument.id);

  prettyPrintYellow('>>> Listen on stream for offer finalised notification');
  notificationStream.stream.where((data) {
    return data.plainTextMessage.isOfType(
      '${getControlPlaneDid()}${MeetingPlaceNotificationTypeSuffix.offerFinalised.value}',
    );
  }).listen((data) async {
    prettyPrintYellow('Received offer finalised message');
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintGreen('>>> Calling SDK.notifyAcceptance');
  await bobSDK.notifyAcceptance(
    connectionOffer: acceptOfferResult.connectionOffer,
    senderInfo: 'Bob',
  );
  prettyPrint('Other party has been notified about acceptance');

  prettyPrintYellow('=== Waiting for Alice to approve connection request...');
  final offerFinalisedEvent = await waitForOfferFinalised.future;
  prettyPrintYellow('>>> Received offer finalised event');
  prettyPrintYellow('Event type: ${offerFinalisedEvent.type.name}');
  prettyJsonPrintYellow('Channel:', offerFinalisedEvent.channel);

  await notificationStream.dispose();
}
