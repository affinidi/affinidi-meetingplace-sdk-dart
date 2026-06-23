import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../../../utils/print.dart';
import '../../../utils/repository/chat_repository_impl.dart';
import '../../../utils/sdk.dart';
import '../../../utils/storage.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  // Bob approves offer
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Bob registers for DIDComm notifications
  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  final outputDirectory = Directory('.example-output');
  final file = File(
    '${outputDirectory.path}${Platform.pathSeparator}storage.txt',
  );
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
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );

  prettyJsonPrintYellow(
    'Acceptance details',
    acceptOfferResult.connectionOffer.toJson(),
  );

  // Listen on control plane events stream to receive updates about
  //  published offer
  prettyPrint('Listen on new events...');
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  // Listen to mediator stream using notification DID
  prettyPrintGreen('>>> Calling SDK.subscribe');
  final notificationStream = await bobSDK.subscribe(
    DidCommSubscription(receiverDid: notificationDidDocument.id),
  );

  prettyPrintYellow('>>> Listen on notification stream');
  final notificationSubscription = notificationStream.stream.listen((
    IncomingMessage message,
  ) async {
    final didcommMessage = message as DidCommIncomingMessage;
    prettyJsonPrintYellow('Received message', didcommMessage.payload.toJson());
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Alice to approve connection request...');
  final offerFinalisedEvent = await waitForOfferFinalised.future;
  prettyPrintYellow('>>> Received offer finalised event');
  prettyPrintYellow('Event type: ${offerFinalisedEvent.type.name}');
  prettyJsonPrintYellow('Channel:', offerFinalisedEvent.channel);

  await notificationSubscription.cancel();

  prettyPrintYellow('Initializing chat...');
  final bobChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    offerFinalisedEvent.channel,
    coreSDK: bobSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options: MeetingPlaceChatSDKOptions(
      chatPresenceSendInterval: const Duration(seconds: 60),
    ),
  );

  await Future<void>.delayed(const Duration(seconds: 2));

  await bobChatSDK.startChatSession();
  await bobChatSDK.chatStreamSubscription.then((stream) {
    stream!.listen((data) {
      if (data.event is ChatMessageEvent) {
        prettyJsonPrintYellow(
          'Received chat item on chat stream',
          data.chatItem!.toJson(),
        );
      }
    });
  });

  prettyPrintGreen(
    '>>> Calling MeetingPlaceChatSDK.sendTextMessage("Hi Alice!")',
  );
  await bobChatSDK.sendTextMessage('Hi Alice!');

  prettyPrintGreen(
    '>>> Calling MeetingPlaceChatSDK.sendTextMessage("How are you?")',
  );
  await bobChatSDK.sendTextMessage('How are you?');

  // Send message manually via core SDK
  await bobSDK.sendMessage(
    DidCommOutgoingMessage(
      senderDid: offerFinalisedEvent.channel.permanentChannelDid!,
      recipientDid: offerFinalisedEvent.channel.otherPartyPermanentChannelDid!,
      payload: PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse(ChatProtocol.chatMessage.value),
        from: offerFinalisedEvent.channel.permanentChannelDid,
        to: [offerFinalisedEvent.channel.otherPartyPermanentChannelDid!],
        body: {'text': 'This is a custom message', 'seqNo': 100},
      ),
    ),
  );
}
