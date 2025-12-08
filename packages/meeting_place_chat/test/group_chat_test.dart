import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/contact_card_fixture.dart';
import 'utils/control_plane_test_utils.dart';
import 'utils/sdk.dart';

void main() async {
  late final MeetingPlaceCoreSDK aliceSDK;
  late final MeetingPlaceCoreSDK bobSDK;
  late final MeetingPlaceCoreSDK charlieSDK;

  late final MeetingPlaceChatSDK aliceChatSDK;
  late final MeetingPlaceChatSDK bobChatSDK;
  late final MeetingPlaceChatSDK charlieChatSDK;

  late final ChannelRepository aliceChannelRepository;
  late final ChannelRepository bobChannelRepository;
  late final ChannelRepository charlieChannelRepository;

  late final DidDocument groupOwnerDidDocument;
  late final String bobMemberDid;
  late final String charlieMemberDid;

  late final Group aliceGroup;
  late final Group bobGroup;
  late final Group charlieGroup;

  late final PublishOfferResult<GroupConnectionOffer> publishOfferResult;

  Future<(MeetingPlaceCoreSDK, AcceptOfferResult)>
      anotherMemberJoinsGroup() async {
    final sdk = await initCoreSDKInstance();

    final acceptance = await sdk.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      contactCard: ContactCard(
        did: 'did:test:charlie',
        type: 'human',
        contactInfo: ContactCardFixture.charliePrimaryCardInfo,
      ),
    );

    return (sdk, acceptance);
  }

  setUpAll(() async {
    aliceChannelRepository = initChannelRepository();
    bobChannelRepository = initChannelRepository();
    charlieChannelRepository = initChannelRepository();

    // Setup wallets and SDK instances of group members
    aliceSDK = await initCoreSDKInstance();
    bobSDK = await initCoreSDKInstance();
    charlieSDK = await initCoreSDKInstance();

    // Publish group offer / create group
    publishOfferResult = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: ContactCard(
        did: 'did:test:alice',
        type: 'human',
        contactInfo: ContactCardFixture.alicePrimaryCardInfo,
      ),
      type: SDKConnectionOfferType.groupInvitation,
    );

    groupOwnerDidDocument =
        await publishOfferResult.groupOwnerDidManager!.getDidDocument();

    // Bob requests group membership
    final bobFindOfferResult = await bobSDK.findOffer(
      mnemonic: publishOfferResult.connectionOffer.mnemonic,
    );
    final bobAcceptance = await bobSDK.acceptOffer(
      connectionOffer: bobFindOfferResult.connectionOffer!,
      contactCard: ContactCard(
        did: 'did:test:bob',
        type: 'human',
        contactInfo: ContactCardFixture.bobPrimaryCardInfo,
      ),
    );

    // Charlie requests group membership
    final charlieFindOfferResult = await charlieSDK.findOffer(
      mnemonic: publishOfferResult.connectionOffer.mnemonic,
    );

    final charlieAcceptance = await charlieSDK.acceptOffer(
      connectionOffer: charlieFindOfferResult.connectionOffer!,
      contactCard: ContactCard(
        did: 'did:test:charlie',
        type: 'human',
        contactInfo: ContactCardFixture.charliePrimaryCardInfo,
      ),
    );

    // Get did documents of each member
    bobMemberDid =
        (bobAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;
    charlieMemberDid =
        (charlieAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;

    final aliceSDKCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 2,
    );

    // Execute event handlers in the background for Alice
    await aliceSDK.processControlPlaneEvents();
    await aliceSDKCompleter.future;

    final bobChannel = await aliceSDK.getChannelByDid(bobMemberDid);
    final charlieChannel = await aliceSDK.getChannelByDid(charlieMemberDid);

    // Alice approves Bob's group membership request
    await aliceSDK.approveConnectionRequest(channel: bobChannel!);

    // Alice approves Charlie's group membership request
    await aliceSDK.approveConnectionRequest(channel: charlieChannel!);

    final bobCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      bobSDK,
      eventType: ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    final charlieCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      charlieSDK,
      eventType: ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await charlieSDK.processControlPlaneEvents();
    await charlieCompleter.future;

    aliceGroup = (await aliceSDK.getGroupByOfferLink(
      publishOfferResult.connectionOffer.offerLink,
    ))!;

    // Initialize chat SDKs for group members
    aliceChatSDK = await initGroupChatSDK(
      coreSDK: aliceSDK,
      did: groupOwnerDidDocument.id,
      otherPartyDid: publishOfferResult.connectionOffer.groupDid!,
      group: aliceGroup,
      channelRepository: aliceChannelRepository,
    );

    bobGroup = (await bobSDK.getGroupByOfferLink(
      publishOfferResult.connectionOffer.offerLink,
    ))!;

    bobChatSDK = await initGroupChatSDK(
      coreSDK: bobSDK,
      did: bobMemberDid,
      otherPartyDid: publishOfferResult.connectionOffer.groupDid!,
      group: bobGroup,
      channelRepository: bobChannelRepository,
    );

    charlieGroup = (await charlieSDK.getGroupByOfferLink(
      publishOfferResult.connectionOffer.offerLink,
    ))!;

    charlieChatSDK = await initGroupChatSDK(
      coreSDK: charlieSDK,
      did: charlieMemberDid,
      otherPartyDid: publishOfferResult.connectionOffer.groupDid!,
      group: charlieGroup,
      channelRepository: charlieChannelRepository,
    );
  });

  // test('member deregisters from group', () async {
  //   await aliceChatSDK.startChatSession();
  //   await bobChatSDK.startChatSession();

  //   final channel = await charlieChannelRepository.findChannelByDid(
  //     charlieMemberDid,
  //   );

  //   final aliceCompleter = Completer<void>();
  //   await aliceChatSDK.chatStreamSubscription.then((stream) {
  //     stream!.listen((data) {
  //       if (data.plainTextMessage?.type.toString() ==
  //           MeetingPlaceProtocol.groupMemberInauguration.value) {
  //         aliceCompleter.complete();
  //       }
  //     });
  //   });

  //   await charlieSDK.leaveChannel(channel!);

  //   // final bobGroupRepresentation = await bobSDK.getGroupById(bobGroup.id);
  //   // final bobMembers = bobGroupRepresentation!.members.where(
  //   //   (member) => member.status == GroupMemberStatus.deleted,
  //   // );

  //   // expect(bobMembers.length, equals(1));

  //   final aliceGroupRepresentation = await aliceSDK.getGroupById(aliceGroup.id);
  //   final aliceMembers = aliceGroupRepresentation!.members.where(
  //     (member) => member.status == GroupMemberStatus.deleted,
  //   );

  //   expect(aliceMembers.length, equals(1));
  // });

  test('group owner sends message to members', () async {
    await bobChatSDK.startChatSession();
    await charlieChatSDK.startChatSession();

    final bobChatCompleter = Completer<PlainTextMessage>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          bobChatCompleter.complete(data.plainTextMessage!);
        }
      });
    });

    final charlieChatCompleter = Completer<PlainTextMessage>();
    await charlieChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.type.toString() ==
            ChatProtocol.chatMessage.value) {
          charlieChatCompleter.complete(data.plainTextMessage!);
        }
      });
    });

    await aliceChatSDK.sendTextMessage('Hello Group!');

    final messageForBob = await bobChatCompleter.future;
    final messageForCharlie = await charlieChatCompleter.future;

    expect(messageForBob.body!['text'], equals('Hello Group!'));
    expect(messageForCharlie.body!['text'], equals('Hello Group!'));
  });

  test('group admin sees concierge message for pending approvals', () async {
    await anotherMemberJoinsGroup();

    final completer = Completer<void>();
    aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    await aliceSDK.processControlPlaneEvents();
    await completer.future;

    final newGroup = await aliceSDK.getGroupById(aliceGroup.id);
    final newAliceChatSDK = await initGroupChatSDK(
      coreSDK: aliceSDK,
      did: groupOwnerDidDocument.id,
      otherPartyDid: publishOfferResult.connectionOffer.groupDid!,
      group: newGroup!,
      channelRepository: aliceChannelRepository,
    );

    final chat = await newAliceChatSDK.startChatSession();
    expect(chat.messages.whereType<ConciergeMessage>().length, equals(1));

    final conciergeMessage = chat.messages.whereType<ConciergeMessage>().first;
    await newAliceChatSDK.approveConnectionRequest(conciergeMessage);

    expect(conciergeMessage.status, ChatItemStatus.confirmed);
  });

  test('group admin rejects connection request', () async {
    final (newMemberSDK, acceptance) = await anotherMemberJoinsGroup();

    final completer = Completer<void>();
    aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationGroupAccept &&
          event.channel.offerLink == acceptance.connectionOffer.offerLink) {
        completer.complete();
      }
    });

    await bobChatSDK.startChatSession();

    await Future.delayed(const Duration(seconds: 2));
    await aliceSDK.processControlPlaneEvents();
    await completer.future;

    final newGroup = await aliceSDK.getGroupById(aliceGroup.id);
    final newAliceChatSDK = await initGroupChatSDK(
      coreSDK: aliceSDK,
      did: groupOwnerDidDocument.id,
      otherPartyDid: publishOfferResult.connectionOffer.groupDid!,
      group: newGroup!,
      channelRepository: aliceChannelRepository,
    );

    final chat = await newAliceChatSDK.startChatSession();

    // Wait to ensure the concierge message is processed
    await Future.delayed(const Duration(seconds: 2));

    final conciergeMessage = chat.messages.whereType<ConciergeMessage>().first;
    await newAliceChatSDK.rejectConnectionRequest(conciergeMessage);

    final newMemberDidDoc =
        await acceptance.permanentChannelDid.getDidDocument();

    final updatedGroup = await aliceSDK.getGroupById(aliceGroup.id);
    expect(conciergeMessage.status, ChatItemStatus.confirmed);
    expect(updatedGroup!.members.length, equals(4));
    expect(
      updatedGroup.members.firstWhereOrNull(
        (member) => member.did == newMemberDidDoc.id,
      ),
      isNull,
    );
  });

  test('send activity message', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();
    await charlieChatSDK.startChatSession();

    final messageReceivedCompleter = Completer<bool>();
    await charlieChatSDK.chatStreamSubscription.then((stream) {
      stream!.listen((data) {
        if (data.plainTextMessage?.isOfType(ChatProtocol.chatActivity.value) ==
            true) {
          messageReceivedCompleter.complete(true);
        }
      });
    });

    await bobChatSDK.sendChatActivity();
    final messageReceived = await messageReceivedCompleter.future;

    expect(messageReceived, isTrue);
  });

  // test('other party sends chat delivered message', () async {
  //   await aliceChatSDK.startChatSession();
  //   await bobChatSDK.startChatSession();
  //   await charlieChatSDK.startChatSession();

  //   var messageReceived = false;
  //   final aliceCompleter = Completer<void>();
  //   await aliceChatSDK.chatStreamSubscription.then((stream) {
  //     stream!.listen((data) {
  //       if (data.plainTextMessage?.type.toString() ==
  //           ChatProtocol.chatDelivered.value) {
  //         messageReceived = true;
  //         if (!aliceCompleter.isCompleted) aliceCompleter.complete();
  //       }
  //     });
  //   });

  //   await aliceChatSDK.sendTextMessage('Hello Group!');
  //   await aliceCompleter.future;

  //   expect(messageReceived, isTrue);
  // });

  // test(
  //     '''shows concierge message request to join group with open
  //websocket subscription''',
  //     () async {
  //   await aliceChatSDK.startChatSession();
  //   await bobChatSDK.startChatSession();

  //   late String memberDid;
  //   final aliceCompleter = Completer<void>();
  //   await aliceChatSDK.channelSubscriptionReady.then((stream) {
  //     stream.listen((data) {
  //       final chatItem = data.chatItem;
  //       if (chatItem is ConciergeMessage) {
  //         memberDid = chatItem.senderDid;
  //         aliceCompleter.complete();
  //       }
  //     });
  //   });

  //   await anotherMemberJoinsGroup();
  //   await aliceCompleter.future;

  //   final messages = await aliceChatSDK.messages;
  //   final actual = messages.firstWhereOrNull(
  //     (message) =>
  //         message is ConciergeMessage &&
  //         message.status == ChatItemStatus.userInput &&
  //         message.data['memberDid'] == memberDid,
  //   );

  //   expect(actual, isNotNull);
  // });
}
