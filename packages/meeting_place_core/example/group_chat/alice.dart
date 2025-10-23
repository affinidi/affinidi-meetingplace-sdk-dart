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
  final publishOfferResult = await aliceSDK.publishOffer<GroupConnectionOffer>(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    vCard: VCard(values: {}),
    type: SDKConnectionOfferType.groupInvitation,
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
  final waitForMembersToJoin = Completer<void>();
  int membersCount = 0;

  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
  aliceSDK.controlPlaneEventsStream.listen((event) async {
    if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
      membersCount++;
      /**
       * Invitation group accept event details
       */
      prettyPrintYellow('>>> Received invitation accepted event');
      prettyPrintYellow('Event type: ${event.type.name}');
      prettyJsonPrintYellow('Channel:', event.channel);

      /**
       * Approve connection request
       */
      prettyPrintGreen('>>> Calling SDK.approveConnectionRequest');
      await aliceSDK.approveConnectionRequest(
        connectionOffer: publishOfferResult.connectionOffer,
        channel: event.channel,
      );

      if (membersCount == 1) {
        waitForMembersToJoin.complete();
      }
    }
  });

  final publishOfferMediatorChannel = await aliceSDK.subscribeToMediator(
    publishOfferResult.connectionOffer.publishOfferDid,
    deleteOnMediator: false,
  );

  publishOfferMediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.connectionSetupGroup.value) {
      await aliceSDK.processControlPlaneEvents();
    }
  });

  prettyPrintYellow('=== Waiting for Members  to accept connection offer...');
  await waitForMembersToJoin.future;
  await publishOfferMediatorChannel.dispose();

  prettyPrintYellow('Initializing chat...');
  final groupChannel = await aliceSDK.getChannelByDid(
    publishOfferResult.connectionOffer.groupOwnerDid!,
  );
  final aliceChatSDK = await ChatSDK.initialiseFromChannel(
    groupChannel!,
    coreSDK: aliceSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options:
        ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 60)),
  );

  await Future.delayed(Duration(seconds: 5));

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
