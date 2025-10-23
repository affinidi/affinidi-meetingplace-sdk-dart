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
  await bobSDK.registerForPushNotifications(const Uuid().v4());

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
    connectionOffer: findOfferResult.connectionOffer as GroupConnectionOffer,
    vCard: VCard(values: {}),
  );

  prettyJsonPrintYellow(
    'Acceptance details',
    acceptOfferResult.connectionOffer.toJson(),
  );

  // Listen on discovery events stream to receive updates about published offer
  prettyPrint('Listen on new events...');
  final waitForGroupMembershipFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.discoveryEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.GroupMembershipFinalised) {
      waitForGroupMembershipFinalised.complete(event);
    }
  });

  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final mediatorChannel = await bobSDK.subscribeToMediator(
    acceptOfferResult.connectionOffer.memberDid!,
    deleteOnMediator: false,
  );

  mediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.groupMemberInauguration.value) {
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

  prettyPrintYellow(
    '=== Waiting for group owner to approve connection request...',
  );
  final groupMembershipFinalised = await waitForGroupMembershipFinalised.future;
  prettyPrintYellow('>>> Received group membership finalised event');
  prettyPrintYellow('Event type: ${groupMembershipFinalised.type.name}');
  prettyJsonPrintYellow('Channel:', groupMembershipFinalised.channel);

  prettyPrintYellow('Initializing chat...');
  final bobChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    groupMembershipFinalised.channel,
    coreSDK: bobSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options:
        ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 60)),
  );

  await Future.delayed(const Duration(seconds: 5));

  await bobChatSDK.startChatSession();
  await bobChatSDK.chatStreamSubscription.then((stream) {
    stream!.listen((data) {
      if (data.plainTextMessage?.body!['fromDid'] ==
          acceptOfferResult.connectionOffer.memberDid) {
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

  prettyPrintGreen('>>> Calling ChatSDK.sendTextMessage("Hi Group!")');
  await bobChatSDK.sendTextMessage('Hi Group!');
}
