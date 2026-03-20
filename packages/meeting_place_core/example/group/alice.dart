import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:matrix/matrix.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

const plainTextMessageTypePrefix =
    'https://affinidi.com/didcomm/protocols/meeting-place-core/';

Future<DidDocument> registerForNotifications(MeetingPlaceCoreSDK sdk) async {
  prettyPrintGray('▶ Register for DIDComm notifications');
  final notification = await sdk.registerForDIDCommNotifications();
  final notificationDidDocument = await notification.recipientDid
      .getDidDocument();
  prettyPrintGreen('✔ Received notification DID ${notificationDidDocument.id}');

  return notificationDidDocument;
}

Future<CoreSDKStreamSubscription> subscribeToNotifications(
  MeetingPlaceCoreSDK sdk,
  DidDocument didDocument,
) async {
  prettyPrintGray(
    '▶ Subscribe DIDComm notifications for DID ${didDocument.id}',
  );

  final notificationStream = await sdk.subscribeToMediator(didDocument.id);

  notificationStream.stream.listen((data) async {
    if (!data.plainTextMessage.type.toString().startsWith(
      plainTextMessageTypePrefix,
    )) {
      return;
    }

    await sdk.processControlPlaneEvents();
  });

  prettyPrintGreen('✔ Subscription for DID ${didDocument.id} setup');
  return notificationStream;
}

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  // Alice registers for DIDComm notifications
  final notificationDidDocument = await registerForNotifications(aliceSDK);
  prettyPrintBoxDevider();

  // Alice subscribes to notification stream via mediator
  final notificationSubscription = await subscribeToNotifications(
    aliceSDK,
    notificationDidDocument,
  );
  prettyPrintBoxDevider();

  // Alice publishes group offer
  prettyPrintGray('▶ Publish group offer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.groupInvitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  final createdGroup = await aliceSDK.getGroupByOfferLink(
    publishOfferResult.connectionOffer.offerLink,
  );

  final file = File('./storage.txt');
  file.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );

  prettyPrintGreen('''✓ Group offer published successfully with mnemonic
    "${publishOfferResult.connectionOffer.mnemonic}"''');
  prettyPrintYellow(
    '⭐ Matrix room created with ID: ${createdGroup!.matrixRoomId}',
  );

  final ownerDidDocument = await publishOfferResult.groupOwnerDidManager!
      .getDidDocument();
  final createdChannel = await aliceSDK.getChannelByDid(ownerDidDocument.id);

  prettyPrintYellow(
    '''⭐ Matrix user ID (Alice) created: ${createdChannel!.matrixUserId} for
    permanent channel DID ${createdChannel.permanentChannelDid}''',
  );
  prettyPrintBoxDevider();

  final publishOfferSubscription = await aliceSDK.subscribeToMediator(
    publishOfferResult.connectionOffer.publishOfferDid,
  );

  publishOfferSubscription.listen((data) async {
    if (data.plainTextMessage.type.toString().startsWith(
      plainTextMessageTypePrefix,
    )) {
      prettyPrintGreen(
        '''🔔 Received DIDComm message "${data.plainTextMessage.type.toString()}"
      for DID ${publishOfferResult.connectionOffer.publishOfferDid}''',
      );

      prettyJsonPrintGray("DIDComm message", data.plainTextMessage.toJson());

      final msg = InvitationAcceptanceGroup.fromPlainTextMessage(
        data.plainTextMessage,
      );
      prettyPrintYellow('''⭐ Received Matrix user ID: ${msg.body.matrixUserId}
      for other party permanent channel did ${msg.body.channelDid}''');
      prettyPrintBoxDevider();

      await aliceSDK.processControlPlaneEvents();
    }

    return MediatorStreamProcessingResult(keepMessage: true);
  });

  // Listen for invitation group acceptance event to know when member
  // accepted the offer and event has been processed.
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
      waitForInvitationAccept.complete(event);
    }
  });

  prettyPrintGray('⏰ Waiting for member to accept offer...');
  final receivedEvent = await waitForInvitationAccept.future;

  prettyPrintGreen('''✓ Processed group invitation accepted event for member
      DID ${receivedEvent.channel.otherPartyPermanentChannelDid}''');
  prettyPrintBoxDevider();

  final group = await aliceSDK.getGroupByOfferLink(
    publishOfferResult.connectionOffer.offerLink,
  );
  final pendingMember = group!.members.firstWhere(
    (member) => member.status == GroupMemberStatus.pendingApproval,
  );

  final memberChannel = await aliceSDK.getChannelByOtherPartyPermanentDid(
    pendingMember.did,
  );

  prettyPrintGray('''▶ Approve connection request for DID
      ${memberChannel!.otherPartyPermanentChannelDid}''');
  await aliceSDK.approveConnectionRequest(channel: memberChannel);
  prettyPrintGreen('''✓ Connection request approved for DID
      ${memberChannel.otherPartyPermanentChannelDid} approved''');
  prettyPrintYellow(
    '''⭐ Matrix user with ID ${memberChannel.otherPartyMatrixUserId} has been
    invited to room ${createdGroup.matrixRoomId}''',
  );
  prettyPrintBoxDevider();

  // Subscribe Alice to mediator stream listening for incoming group messages
  final adminMemberDidManager = publishOfferResult.groupOwnerDidManager;
  final adminMemberDidDocument = await adminMemberDidManager!.getDidDocument();

  final subscription = await aliceSDK.subscribeToMediator(
    adminMemberDidDocument.id,
  );

  final waitForChannelActivity = Completer<PlainTextMessage>();
  subscription.listen((data) async {
    if (data.plainTextMessage.type ==
        Uri.parse(
          'https://affinidi.com/didcomm/protocols/meeting-place-chat/1.0/message',
        )) {
      waitForChannelActivity.complete(data.plainTextMessage);
    }
    return MediatorStreamProcessingResult(keepMessage: false);
  });

  final waitForGroupMessage = Completer<Event>();
  final timelineStream = await aliceSDK.subscribeToMatrixTimeline(
    'did:test:alice',
  );
  timelineStream.listen((event) {
    if (event.type == 'm.room.member' &&
        event.content['membership'] == 'join') {
      prettyPrintGreen('✓ User ${event.stateKey} joined room ${event.roomId}');
      prettyJsonPrintGray('Matrix payload :: m.room.member', event.toJson());
    } else {
      waitForGroupMessage.complete(event);
    }
  });

  prettyPrintGray('⏰ Waiting to receive group message...');
  prettyPrintBoxDevider();
  final receivedGroupMessage = await waitForGroupMessage.future;
  prettyPrintGreen('✓ Received group message');
  prettyJsonPrintGray('Group message', receivedGroupMessage.toJson());
  prettyPrintBoxDevider();

  await notificationSubscription.dispose();
  await subscription.dispose();
  await publishOfferSubscription.dispose();
}
