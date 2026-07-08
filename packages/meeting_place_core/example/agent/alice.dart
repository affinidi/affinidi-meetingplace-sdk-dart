import 'dart:async';

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

  // Alice publishes offer
  final bobAgentDid =
      'did:key:zDnaeXf4xGHGwy6aj4knb3kS3DZ6aeNg3MytMxdjY7ojYQ5v1';

  final aliceSDK = await initSDK(
    wallet: PersistentWallet(InMemoryKeyStore()),
  );
  prettyPrintGreen('[Alice] ✓ SDK initialized, agent DID: $bobAgentDid');

  final bobSDK = await initSDK(
    wallet: PersistentWallet(InMemoryKeyStore()),
    agentDid: bobAgentDid,
  );
  prettyPrintGreen('[Bob] ✓ SDK initialized');

  // Alice registers for DIDComm notifications
  final aliceNotification = await aliceSDK.registerForDIDCommNotifications();
  final aliceNotificationDidDocument =
      await aliceNotification.recipientDid.getDidDocument();
  prettyPrintGreen(
      '[Alice] ✓ Notification DID ${aliceNotificationDidDocument.id}');

  // Bob registers for DIDComm notifications
  final bobNotification = await bobSDK.registerForDIDCommNotifications();
  final bobNotificationDidDocument =
      await bobNotification.recipientDid.getDidDocument();
  prettyPrintGreen('[Bob] ✓ Notification DID ${bobNotificationDidDocument.id}');

  // Alice publishes offer
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
    transport: ChannelTransport.didcomm,
  );
  prettyPrintGreen(
    '''[Alice] ✓ Published offer mnemonic ${publishOfferResult.connectionOffer.mnemonic}''',
  );

  // Listen on control plane events stream to receive updates
  // about published offer
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
  prettyPrintYellow('[Alice] Listen on new events...');

  // Alice listens to mediator stream using notification DID
  final notificationStream = await aliceSDK.subscribe(
    DidCommSubscription(receiverDid: aliceNotificationDidDocument.id),
  );

  notificationStream.stream.listen((IncomingMessage message) async {
    await aliceSDK.processControlPlaneEvents();
  });
  prettyPrintYellow('[Alice] Listen on notification stream');
  prettyPrintYellow('[Alice] Waiting for Bob to accept connection offer...');

  // Bob finds offer and accepts it
  final findOfferResult = await bobSDK.findOffer(
    mnemonic: publishOfferResult.connectionOffer.mnemonic,
  );
  prettyPrintGreen(
      '[Bob] ✓ Offer found for ${publishOfferResult.connectionOffer.mnemonic}');

  await bobSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );
  prettyPrintGreen(
      '''[Bob] ✓ Accepted offer for ${publishOfferResult.connectionOffer.mnemonic}''');

  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  final bobNotificationStream = await bobSDK.subscribe(
    DidCommSubscription(receiverDid: bobNotificationDidDocument.id),
  );

  bobNotificationStream.stream.listen((IncomingMessage message) async {
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('[Bob] Waiting for Alice to approve connection request...');

  final receivedEvent = await waitForInvitationAccept.future;
  prettyPrintGreen(
    '[Alice] ✓ Received invitation acceptance DIDComm message by Bob.',
  );

  await aliceSDK.approveConnectionRequest(channel: receivedEvent.channel);
  prettyPrintGreen('[Alice] ✓ Approved connection request');

  await waitForOfferFinalised.future;
  prettyPrintGreen('[Bob] ✓ Received offer finalised event from Alice.');

  prettyPrintYellow(
    '[Alice] Waiting for Bob to send channel inauguraten message...',
  );

  final receivedChannelActivityEvent = await waitForChannelActivity.future;
  prettyPrintYellow('Event type: ${receivedChannelActivityEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedChannelActivityEvent.channel);

  final aliceChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    receivedChannelActivityEvent.channel,
    coreSDK: aliceSDK,
    chatRepository: _InMemoryChatRepository(),
    options: MeetingPlaceChatSDKOptions(),
  );
  await aliceChatSDK.startChatSession();
  prettyPrintGreen('[Alice] ✓ Chat session started');

  await aliceChatSDK.sendTextMessage('Hello Bob!');
  prettyPrintGreen('[Alice] ✓ Sent message to Bob');
  prettyPrintGreen(
      '''[Alice] ✓ My permanent channel DID: ${receivedChannelActivityEvent.channel.permanentChannelDid}, Bob's permanent channel DID: ${receivedChannelActivityEvent.channel.otherPartyPermanentChannelDid}, Bob's agent permanent channel DID: ${receivedChannelActivityEvent.channel.otherPartyAgentPermanentChannelDid}''');
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
