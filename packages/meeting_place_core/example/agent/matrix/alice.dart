import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../../utils/print.dart';
import '../../utils/sdk.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final aliceSDK = await initSDK(
    wallet: PersistentWallet(InMemoryKeyStore()),
  );
  prettyPrintGreen('[Alice] ✓ SDK initialized');

  // Alice registers for DIDComm notifications
  final aliceNotification = await aliceSDK.registerForDIDCommNotifications();
  final aliceNotificationDidDocument =
      await aliceNotification.recipientDid.getDidDocument();
  prettyPrintGreen(
      '[Alice] ✓ Notification DID ${aliceNotificationDidDocument.id}');

  // Alice publishes offer using Matrix transport
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    transport: ChannelTransport.matrix,
  );
  prettyPrintGreen(
    '[Alice] ✓ Published offer mnemonic '
    '${publishOfferResult.connectionOffer.mnemonic}',
  );

  // Write mnemonic to file so Bob can read it
  final outputDirectory = Directory('.example-output')
    ..createSync(recursive: true);
  final mnemonicFile = File(
    '${outputDirectory.path}${Platform.pathSeparator}mnemonic.txt',
  );
  mnemonicFile.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );
  prettyPrintGreen('[Alice] ✓ Mnemonic written to ${mnemonicFile.path}');

  // Listen on control plane events stream
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }
    if (event.type == ControlPlaneEventType.ChannelActivity) {
      if (!waitForChannelActivity.isCompleted) {
        waitForChannelActivity.complete(event);
      }
    }
  });
  prettyPrintYellow('[Alice] Listening for events...');

  // Subscribe to DIDComm notification stream
  final notificationStream = await aliceSDK.subscribe(
    DidCommSubscription(receiverDid: aliceNotificationDidDocument.id),
  );

  final notificationSubscription =
      notificationStream.stream.listen((IncomingMessage message) async {
    await aliceSDK.processControlPlaneEvents();
  });
  prettyPrintYellow('[Alice] Listening on notification stream');
  prettyPrintYellow('[Alice] Waiting for Bob to accept connection offer...');

  final receivedEvent = await waitForInvitationAccept.future;
  prettyPrintGreen('[Alice] ✓ Received invitation acceptance from Bob.');

  // approveConnectionRequest returns the channel with Matrix credentials
  final channel = await aliceSDK.approveConnectionRequest(
    channel: receivedEvent.channel,
  );
  prettyPrintGreen('[Alice] ✓ Approved connection request');

  prettyPrintYellow(
    '[Alice] Waiting for Bob to send channel inauguration message...',
  );

  final receivedChannelActivityEvent = await waitForChannelActivity.future;
  prettyPrintYellow('Event type: ${receivedChannelActivityEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedChannelActivityEvent.channel);

  await notificationSubscription.cancel();
  prettyPrintGreen('[Alice] ✓ Notification subscription cancelled');

  final aliceChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    channel,
    coreSDK: aliceSDK,
    chatRepository: _InMemoryChatRepository(),
    options: MeetingPlaceChatSDKOptions(),
  );

  await aliceChatSDK.startChatSession();
  prettyPrintGreen('[Alice] ✓ Chat session started');

  await aliceChatSDK.chatStreamSubscription.then((chatStream) {
    chatStream?.listen((data) {
      final item = data.chatItem;
      if (item is Message && item.isFromMe == false) {
        prettyPrintGreen(
          '[Alice] ✓ Received message from '
          '${item.senderDid}: ${item.value}',
        );
      }
    });
    prettyPrintYellow(
      '[Alice] Listening on chat stream using DID '
      '${channel.permanentChannelDid}...',
    );
  });

  await aliceChatSDK.sendTextMessage('Hello, what is your name?');
  prettyPrintGreen('[Alice] ✓ Sent message to Bob');
  prettyPrintGreen(
    '[Alice] ✓ My permanent channel DID: '
    '${channel.permanentChannelDid}',
  );
  prettyPrintGreen(
    "[Alice] ✓ Bob's permanent channel DID: "
    '${channel.otherPartyPermanentChannelDid}',
  );
  prettyPrintGreen(
    "[Alice] ✓ Bob's agent permanent channel DID: "
    '${channel.otherPartyAgentPermanentChannelDid}',
  );
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
