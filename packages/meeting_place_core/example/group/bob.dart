import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();

  final file = File('.example-output${Platform.pathSeparator}group.txt');
  final mnemonicBytes = file.readAsBytesSync();
  final findOfferResult = await bobSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );
  final connectionOffer = findOfferResult.connectionOffer;
  if (connectionOffer is! GroupConnectionOffer) {
    throw StateError('Expected a group connection offer');
  }

  prettyJsonPrintYellow('Offer details', connectionOffer.toJson());

  final acceptOfferResult = await bobSDK.acceptOffer<GroupConnectionOffer>(
    connectionOffer: connectionOffer,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );
  final memberDidDocument =
      await acceptOfferResult.permanentChannelDid.getDidDocument();
  prettyPrintYellow('Group member DID ${memberDidDocument.id}');

  final waitForMembershipFinalised = Completer<ControlPlaneStreamEvent>();
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.GroupMembershipFinalised &&
        !waitForMembershipFinalised.isCompleted) {
      waitForMembershipFinalised.complete(event);
    }
  });

  final notificationStream = await bobSDK.subscribeToMediator(
    notificationDidDocument.id,
  );
  notificationStream.stream.listen((data) async {
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Alice to approve the group membership...');
  final membershipFinalisedEvent = await waitForMembershipFinalised.future;
  final finalisedChannel = membershipFinalisedEvent.channel;
  final matrixRoomId = finalisedChannel.matrixRoomId;
  if (matrixRoomId == null) {
    throw StateError('Missing Matrix room ID on finalised group channel');
  }

  prettyJsonPrintYellow('Finalised group channel', finalisedChannel.toJson());
  prettyPrintYellow('Shared Matrix room ID: $matrixRoomId');

  await notificationStream.dispose();
}
