import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final bobAgentDid =
      'did:key:zDnaeyLZAEbGDkCXqZFJLfJRsrkSF9feDCm8V5XBMYKe4xrLR';

  final bobSDK = await initSDK(
    wallet: PersistentWallet(InMemoryKeyStore()),
    agentDid: bobAgentDid,
  );
  prettyPrintGreen('[Bob] ✓ SDK initialized');

  // Bob registers for DIDComm notifications
  final bobNotification = await bobSDK.registerForDIDCommNotifications();
  final bobNotificationDidDocument =
      await bobNotification.recipientDid.getDidDocument();
  prettyPrintGreen('[Bob] ✓ Notification DID ${bobNotificationDidDocument.id}');

  // Read mnemonic written by Alice
  final mnemonicFile = File(
    '.example-output${Platform.pathSeparator}mnemonic.txt',
  );
  final mnemonic = utf8.decode(mnemonicFile.readAsBytesSync());
  prettyPrintGreen('[Bob] ✓ Read mnemonic: $mnemonic');

  // Bob finds and accepts offer
  final findOfferResult = await bobSDK.findOffer(mnemonic: mnemonic);
  prettyPrintGreen('[Bob] ✓ Offer found for $mnemonic');

  await bobSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );
  prettyPrintGreen('[Bob] ✓ Accepted offer for $mnemonic');

  // Listen on control plane events stream
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  // Subscribe to DIDComm notification stream
  final bobNotificationStream = await bobSDK.subscribe(
    DidCommSubscription(receiverDid: bobNotificationDidDocument.id),
  );

  final bobNotificationSubscription =
      bobNotificationStream.stream.listen((IncomingMessage message) async {
    await bobSDK.processControlPlaneEvents();
  });
  prettyPrintYellow('[Bob] Waiting for Alice to approve connection request...');

  final offerFinalisedEvent = await waitForOfferFinalised.future;
  prettyPrintGreen('[Bob] ✓ Received offer finalised event from Alice.');

  await bobNotificationSubscription.cancel();
  prettyPrintGreen('[Bob] ✓ Notification subscription cancelled');

  final bobChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    offerFinalisedEvent.channel,
    coreSDK: bobSDK,
    chatRepository: _InMemoryChatRepository(),
    options: MeetingPlaceChatSDKOptions(),
  );

  await bobChatSDK.startChatSession();
  prettyPrintGreen('[Bob] ✓ Chat session started');

  await bobChatSDK.chatStreamSubscription.then((chatStream) {
    chatStream?.listen((data) {
      final item = data.chatItem;
      if (item is Message && item.isFromMe == false) {
        prettyPrintGreen(
            '[Bob] ✓ Received message from ${item.senderDid}: ${item.value}');
      }
    });
    prettyPrintYellow(
        '''[Bob] Listening on chat stream using DID ${offerFinalisedEvent.channel.permanentChannelDid}...''');
  });

  await bobChatSDK.sendTextMessage('Hi Alice, my name is Bob!');
  prettyPrintGreen('[Bob] ✓ Sent reply to Alice');
  prettyPrintGreen(
      '''[Bob] ✓ My permanent channel DID: ${offerFinalisedEvent.channel.permanentChannelDid}''');
  prettyPrintGreen(
      '''[Bob] ✓ Alice's permanent channel DID: ${offerFinalisedEvent.channel.otherPartyPermanentChannelDid}''');
}

class _InMemoryChatRepository implements ChatRepository {
  final _items = <String, ChatItem>{};
  final _markers = <String, String>{};

  @override
  Future<ChatItem> createMessage(ChatItem message) async {
    _items[message.messageId] = message;
    return message;
  }

  @override
  Future<ChatItem> updateMesssage(ChatItem message) async {
    _items[message.messageId] = message;
    return message;
  }

  @override
  Future<List<ChatItem>> listMessages(String chatId) async =>
      _items.values.toList();

  @override
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  }) async =>
      _items[messageId];

  @override
  Future<String?> getSyncMarker(String chatId) async => _markers[chatId];

  @override
  Future<void> updateSyncMarker({
    required String chatId,
    required String eventId,
  }) async =>
      _markers[chatId] = eventId;
}
