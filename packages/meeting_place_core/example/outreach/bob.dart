import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  // Bob publishes offer
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  await bobSDK.registerForPushNotifications(const Uuid().v4());

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await bobSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    vCard: VCard(values: {}),
    type: SDKConnectionOfferType.outreachInvitation,
  );

  final file = File('./storage.txt');
  file.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );

  prettyJsonPrintYellow(
    'Connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  // Listen on discovery events stream to wait for outreach invitation
  prettyPrintYellow('Listen on new events...');
  final waitForOutreachInvitation = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationOutreach) {
      waitForOutreachInvitation.complete(event);
    }
  });

  final publishOfferMediatorChannel = await bobSDK.subscribeToMediator(
    publishOfferResult.connectionOffer.publishOfferDid,
    deleteOnMediator: false,
  );

  publishOfferMediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.outreachInvitation.value) {
      prettyPrintYellow('Received outreach invitation message');
      prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
      await bobSDK.processControlPlaneEvents();
    }
  });

  prettyPrintYellow('=== Waiting for Alice to send outrach invitation');

  final receivedEvent = await waitForOutreachInvitation.future;
  prettyPrintYellow('Received invitation outreach event');
  prettyJsonPrintYellow('Event channel', receivedEvent.channel.toJson());
}
