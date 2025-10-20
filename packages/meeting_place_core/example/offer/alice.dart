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
  // Alice publishes offer
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  await aliceSDK.registerForPushNotifications(const Uuid().v4());

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    vCard: VCard(values: {}),
    customPhrase: 'abc',
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

  // Listen on discovery events stream to receive updates about published offer
  prettyPrintYellow('Listen on new events...');
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
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

  final publishOfferMediatorChannel = await aliceSDK.subscribeToMediator(
    publishOfferResult.connectionOffer.publishOfferDid,
    deleteOnMediator: false,
  );

  publishOfferMediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.connectionSetup.value) {
      await aliceSDK.processControlPlaneEvents();
    }
  });

  prettyPrintYellow('=== Waiting for Bob to accept connection offer...');
  final receivedEvent = await waitForInvitationAccept.future;

  prettyPrintYellow('>>> Received invitation accepted event');
  prettyPrintYellow('Event type: ${receivedEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedEvent.channel);

  prettyPrintGreen('>>> Calling SDK.approveConnectionRequest');
  final channel = await aliceSDK.approveConnectionRequest(
    connectionOffer: publishOfferResult.connectionOffer,
    channel: receivedEvent.channel,
  );

  final permanentChannelDidMediatorChannel = await aliceSDK.subscribeToMediator(
    channel.permanentChannelDid!,
    deleteOnMediator: false,
  );

  permanentChannelDidMediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.channelInauguration.value) {
      await aliceSDK.processControlPlaneEvents();
    }
  });

  prettyPrintYellow(
    '=== Waiting for Bob to send channel inauguration message...',
  );
  final receivedChannelActivityEvent = await waitForChannelActivity.future;
  prettyPrintYellow('Event type: ${receivedChannelActivityEvent.type.name}');
  prettyJsonPrintYellow('Channel:', receivedChannelActivityEvent.channel);

  await publishOfferMediatorChannel.dispose();

  prettyPrintYellow('Initializing chat...');
  final aliceChatSDK = await ChatSDK.initialiseFromChannel(
    channel,
    coreSDK: aliceSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options: ChatSDKOptions(chatPresenceSendInterval: 60),
  );

  await aliceChatSDK.startChatSession();
  await aliceChatSDK.chatStreamSubscription.then((stream) {
    stream!.listen((data) {
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
