import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/repository/chat_repository_impl.dart';
import '../utils/sdk.dart';
import '../utils/storage.dart';

void main() async {
  // Bob approves offer
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  await bobSDK.registerForDIDCommNotifications();

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

  // Listen on discovery events stream to receive updates about published offer
  prettyPrint('Listen on new events...');
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final mediatorChannel = await bobSDK.subscribeToMediator(
    acceptOfferResult.connectionOffer.acceptOfferDid!,
    deleteOnMediator: false,
  );

  mediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.connectionAccepted.value) {
      await Future.delayed(Duration(seconds: 3));
      await bobSDK.processControlPlaneEvents();
    }
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

  prettyPrintYellow('Initializing chat...');
  final bobChatSDK = await ChatSDK.initialiseFromChannel(
    offerFinalisedEvent.channel,
    coreSDK: bobSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options:
        ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 60)),
  );

  await Future.delayed(const Duration(seconds: 2));

  await bobChatSDK.startChatSession();
  await bobChatSDK.chatStreamSubscription.then((stream) {
    stream!.listen((data) {
      if (data.plainTextMessage?.from ==
          offerFinalisedEvent.channel.permanentChannelDid) {
        return;
      }
      if (data.plainTextMessage != null) {
        prettyJsonPrintYellow(
          'Received message on chat stream',
          data.plainTextMessage!.toJson(),
        );
      }

      if (data.chatItem != null) {
        prettyJsonPrintYellow(
          'Received chat item on chat stream',
          data.chatItem!.toJson(),
        );
      }
    });
  });

  prettyPrintGreen('>>> Calling ChatSDK.sendTextMessage("Hi Alice!")');
  await bobChatSDK.sendTextMessage('Hi Alice!');

  prettyPrintGreen('>>> Calling ChatSDK.sendTextMessage("How are you?")');
  await bobChatSDK.sendTextMessage('How are you?');

  // Send message manually via core SDK
  await bobSDK.sendMessage(
    PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: offerFinalisedEvent.channel.permanentChannelDid,
      to: [offerFinalisedEvent.channel.otherPartyPermanentChannelDid!],
      body: {'text': 'This is a custom message', 'seqNo': 100},
    ),
    senderDid: offerFinalisedEvent.channel.permanentChannelDid!,
    recipientDid: offerFinalisedEvent.channel.otherPartyPermanentChannelDid!,
  );
}
