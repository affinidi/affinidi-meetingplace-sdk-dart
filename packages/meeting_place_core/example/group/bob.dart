import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  // Bob approves offer
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Bob registers for DIDComm notifications
  prettyPrintGray('▶ Register for DIDComm notifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument = await notification.recipientDid
      .getDidDocument();
  prettyPrintGreen('✔ Received notification DID ${notificationDidDocument.id}');
  prettyPrintBoxDevider();

  // Listen on control plane events stream to receive updates about
  // published offer
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.GroupMembershipFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  prettyPrintGray(
    '▶ Subscribe DIDComm notifications for DID ${notificationDidDocument.id}',
  );
  final notificationStream = await bobSDK.subscribeToMediator(
    notificationDidDocument.id,
  );
  notificationStream.stream.listen((data) async {
    if (data.plainTextMessage.type.toString().startsWith(
      'https://affinidi.com/didcomm/protocols/meeting-place-core/',
    )) {
      await bobSDK.processControlPlaneEvents();
    }
  });

  prettyPrintGreen(
    '✔ Subscription for DID ${notificationDidDocument.id} setup',
  );
  prettyPrintBoxDevider();

  final file = File('./storage.txt');
  final mnemonicBytes = file.readAsBytesSync();

  prettyPrintGray(
    '▶ Accept group offer with mnemonic "${utf8.decode(mnemonicBytes)}"',
  );

  final findOfferResult = await bobSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );

  final acceptOfferResult = await bobSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );

  final permanentChannelDidManager = acceptOfferResult.permanentChannelDid;
  final permanentChannelDidDocument = await permanentChannelDidManager
      .getDidDocument();

  final channelCreated = await bobSDK.getChannelByDid(
    permanentChannelDidDocument.id,
  );

  prettyPrintGreen('''✓ Group offer accepted successfully with mnemonic
    "${acceptOfferResult.connectionOffer.mnemonic}"''');
  prettyPrintBoxDevider();

  prettyPrintYellow(
    '''⭐ Matrix user ID (Bob) created: ${channelCreated!.matrixUserId}
    for permanent channel DID ${permanentChannelDidDocument.id}''',
  );
  prettyPrintBoxDevider();

  prettyPrintGray(
    '▶ Subscribe mediator for DID ${permanentChannelDidDocument.id}',
  );
  final permanentChannelSubscription = await bobSDK.subscribeToMediator(
    permanentChannelDidDocument.id,
  );
  permanentChannelSubscription.listen((data) async {
    if (data.plainTextMessage.type.toString().startsWith(
      'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/group-member-inauguration',
    )) {
      prettyPrintGreen(
        '''🔔 Received DIDComm message "${data.plainTextMessage.type.toString()}"
      for DID ${permanentChannelDidDocument.id}''',
      );

      prettyJsonPrintGray("DIDComm message", data.plainTextMessage.toJson());

      final msg = GroupMemberInauguration.fromPlainTextMessage(
        data.plainTextMessage,
      );
      prettyPrintYellow('⭐ Received Matrix room ID: ${msg.body.matrixRoomId}');
      prettyPrintBoxDevider();

      await bobSDK.processControlPlaneEvents();
    }
    return MediatorStreamProcessingResult(keepMessage: true);
  });

  prettyPrintGreen(
    '✔ Subscription for DID ${permanentChannelDidDocument.id} setup',
  );
  prettyPrintBoxDevider();

  prettyPrintGray('⏰ Waiting for invite / approval...');
  prettyPrintBoxDevider();

  final offerFinalisedEvent = await waitForOfferFinalised.future;
  prettyPrintGreen('''✓ Received approval for group for member DID
    ${offerFinalisedEvent.channel.permanentChannelDid}''');
  prettyPrintBoxDevider();

  final groupMessage = PlainTextMessage(
    id: const Uuid().v4(),
    from: offerFinalisedEvent.channel.permanentChannelDid!,
    to: [offerFinalisedEvent.channel.otherPartyPermanentChannelDid!],
    type: Uri.parse(
      'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/message',
    ),
    body: {
      'text': 'Hello Alice! This is Bob.',
      'seq_no': 1,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  );

  await bobSDK.sendGroupMessage(
    groupMessage,
    senderDid: offerFinalisedEvent.channel.permanentChannelDid!,
    recipientDid: offerFinalisedEvent.channel.otherPartyPermanentChannelDid!,
    increaseSequenceNumber: true,
  );

  prettyPrintGreen('✓ Group message sent');
  prettyJsonPrintGray('', groupMessage.toJson());
  prettyPrintBoxDevider();

  await notificationStream.dispose();
  await permanentChannelSubscription.dispose();
}
