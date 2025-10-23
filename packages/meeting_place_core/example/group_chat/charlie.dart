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
  // Charlie approves offer
  final charlieSDK = await initSDK(
    wallet: PersistentWallet(InMemoryKeyStore()),
  );
  await charlieSDK.registerForPushNotifications(const Uuid().v4());

  final file = File('./storage.txt');
  final mnemonicBytes = file.readAsBytesSync();

  prettyPrintGreen('>>> Calling SDK.findOffer');
  final findOfferResult = await charlieSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );
  prettyJsonPrintYellow(
    'Offer details',
    findOfferResult.connectionOffer!.toJson(),
  );

  prettyPrintGreen('>>> Calling SDK.acceptOffer');
  final acceptOfferResult = await charlieSDK.acceptOffer(
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
  charlieSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.GroupMembershipFinalised) {
      waitForGroupMembershipFinalised.complete(event);
    }
  });

  prettyPrintGreen('>>> Calling SDK.subscribeToMediator');
  final mediatorChannel = await charlieSDK.subscribeToMediator(
    acceptOfferResult.connectionOffer.memberDid!,
    deleteOnMediator: false,
  );

  mediatorChannel.stream.listen((data) async {
    if (data.plainTextMessage.type.toString() ==
        MeetingPlaceProtocol.groupMemberInauguration.value) {
      await Future.delayed(Duration(seconds: 3));
      await charlieSDK.processControlPlaneEvents();
    }
  });

  prettyPrintGreen('>>> Calling SDK.notifyAcceptance');
  await charlieSDK.notifyAcceptance(
    connectionOffer: acceptOfferResult.connectionOffer,
    senderInfo: 'Charlie',
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
  final charlieChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    groupMembershipFinalised.channel,
    coreSDK: charlieSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options:
        ChatSDKOptions(chatPresenceSendInterval: const Duration(seconds: 60)),
  );

  await Future.delayed(const Duration(seconds: 2));

  await charlieChatSDK.startChatSession();
  await charlieChatSDK.chatStreamSubscription.then((stream) {
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

  prettyPrintGreen(
    '>>> Calling ChatSDK.sendTextMessage("Hi, its me Charlie!")',
  );
  await charlieChatSDK.sendTextMessage('Hi, its me Charlie!');
}
