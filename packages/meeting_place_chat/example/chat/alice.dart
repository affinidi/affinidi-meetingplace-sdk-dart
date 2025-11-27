import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ssi/ssi.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../utils/print.dart';
import '../utils/repository/chat_repository_impl.dart';
import '../utils/sdk.dart';
import '../utils/storage.dart';

void main() async {
  // Alice publishes offer
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Alice registers for DIDComm notifications
  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await aliceSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    vCard: ContactCard(values: {}),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  final file = File('./storage.txt');
  file.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );

  prettyJsonPrintYellow(
    'Connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  // Listen on control plane events stream to receive updates about
  // published offer
  prettyPrintYellow('Listen on new events...');
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
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

  // Alice listens to mediator stream using notification DID
  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final notificationStream =
      await aliceSDK.subscribeToMediator(notificationDidDocument.id);

  prettyPrintYellow('>>> Listen on notification stream');
  notificationStream.stream
      .where((data) => data.plainTextMessage.type
          .toString()
          .startsWith(getControlPlaneDid()))
      .listen((data) async {
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await aliceSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Bob to accept connection offer...');
  final receivedEvent = await waitForInvitationAccept.future;

  prettyPrintYellow('>>> Received invitation accepted event');
  prettyPrintYellow('Event type: ${receivedEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedEvent.channel);

  prettyPrintGreen('>>> Calling SDK.approveConnectionRequest');
  final channel = await aliceSDK.approveConnectionRequest(
    channel: receivedEvent.channel,
  );

  prettyPrintYellow(
    '=== Waiting for Bob to send channel inauguration message...',
  );
  final receivedChannelActivityEvent = await waitForChannelActivity.future;
  prettyPrintYellow('Event type: ${receivedChannelActivityEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedChannelActivityEvent.channel);

  await notificationStream.dispose();

  prettyPrintYellow('Initializing chat...');
  final aliceChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    channel,
    coreSDK: aliceSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options:
        ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 60)),
  );

  await aliceChatSDK.startChatSession();
  await aliceChatSDK.chatStreamSubscription.then((stream) {
    stream?.listen((data) {
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
}
