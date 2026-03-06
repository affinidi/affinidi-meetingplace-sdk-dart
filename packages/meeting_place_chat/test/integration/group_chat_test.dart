import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/contact_card_fixture.dart';
import '../utils/control_plane_test_utils.dart';
import '../utils/sdk.dart';

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
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:charlie',
        contactInfo: ContactCardFixture.charliePrimaryCardInfo,
      ),
      senderInfo: 'Charlie',
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
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: ContactCardFixture.alicePrimaryCardInfo,
      ),
      type: SDKConnectionOfferType.groupInvitation,
    );

    groupOwnerDidDocument = await publishOfferResult.groupOwnerDidManager!
        .getDidDocument();

    // Bob requests group membership
    final bobFindOfferResult = await bobSDK.findOffer(
      mnemonic: publishOfferResult.connectionOffer.mnemonic,
    );
    final bobAcceptance = await bobSDK.acceptOffer(
      connectionOffer: bobFindOfferResult.connectionOffer!,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: ContactCardFixture.bobPrimaryCardInfo,
      ),
      senderInfo: 'Bob',
    );

    // Charlie requests group membership
    final charlieFindOfferResult = await charlieSDK.findOffer(
      mnemonic: publishOfferResult.connectionOffer.mnemonic,
    );

    final charlieAcceptance = await charlieSDK.acceptOffer(
      connectionOffer: charlieFindOfferResult.connectionOffer!,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:charlie',
        contactInfo: ContactCardFixture.charliePrimaryCardInfo,
      ),
      senderInfo: 'Charlie',
    );

    // Get did documents of each member
    bobMemberDid =
        (bobAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;
    charlieMemberDid =
        (charlieAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;

    final aliceSDKCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.InvitationGroupAccept &&
          event.channel.otherPartyPermanentChannelDid ==
              publishOfferResult.connectionOffer.groupDid,
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
      filter: (event) =>
          event.type == ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    final charlieCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      charlieSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.GroupMembershipFinalised,
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
    final charlieChatCompleter = Completer<PlainTextMessage>();

    // Wait for both streams to be ready before sending the message
    final streams = await Future.wait([
      bobChatSDK.chatStreamSubscription,
      charlieChatSDK.chatStreamSubscription,
    ]);

    final bobStream = streams[0]!;
    final charlieStream = streams[1]!;

    void handleMessage({
      required Completer completer,
      required PlainTextMessage? message,
    }) {
      if (message == null ||
          !message.isOfType(ChatProtocol.chatMessage.value)) {
        return;
      }

      final chatMessage = ChatMessage.fromPlainTextMessage(message);
      if (chatMessage.body.text == 'Hello Group!' && !completer.isCompleted) {
        completer.complete(message);
      }
    }

    bobStream.listen((data) {
      handleMessage(
        completer: bobChatCompleter,
        message: data.plainTextMessage,
      );
    });

    charlieStream.listen((data) {
      handleMessage(
        completer: charlieChatCompleter,
        message: data.plainTextMessage,
      );
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

    final newMemberDidDoc = await acceptance.permanentChannelDid
        .getDidDocument();

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
    await charlieChatSDK.chatStreamSubscription.then((stream) async {
      stream!.listen((data) {
        if (data.plainTextMessage?.isOfType(ChatProtocol.chatActivity.value) ==
            true) {
          if (!messageReceivedCompleter.isCompleted) {
            messageReceivedCompleter.complete(true);
            stream.dispose();
          }
        }
      });

      await bobChatSDK.sendChatActivity();
    });

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

  test('group member sendMessage sets from/to and delivers to group', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();
    await charlieChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();
    final bobChatStream = await bobChatSDK.chatStreamSubscription;
    bobChatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (!bobCompleter.isCompleted) {
          bobCompleter.complete(data.plainTextMessage!);
          bobChatStream.dispose();
        }
      }
    });

    final charlieCompleter = Completer<PlainTextMessage>();
    final charlieChatStream = await charlieChatSDK.chatStreamSubscription;
    charlieChatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (!charlieCompleter.isCompleted) {
          charlieCompleter.complete(data.plainTextMessage!);
          charlieChatStream.dispose();
        }
      }
    });

    final message = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: groupOwnerDidDocument.id,
      to: [publishOfferResult.connectionOffer.groupDid!],
      body: {
        'text': 'Hello group via sendMessage',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await aliceChatSDK.sendMessage(message);

    final receivedByBob = await bobCompleter.future;
    final receivedByCharlie = await charlieCompleter.future;

    expect(receivedByBob.body!['text'], equals('Hello group via sendMessage'));
    expect(receivedByBob.from, equals(groupOwnerDidDocument.id));
    expect(
      receivedByBob.to?.first,
      equals(publishOfferResult.connectionOffer.groupDid!),
    );

    expect(
      receivedByCharlie.body!['text'],
      equals('Hello group via sendMessage'),
    );
    expect(receivedByCharlie.from, equals(groupOwnerDidDocument.id));
    expect(
      receivedByCharlie.to?.first,
      equals(publishOfferResult.connectionOffer.groupDid!),
    );
  });

  test('group sendMessage throws if from/to are set incorrectly', () async {
    await aliceChatSDK.startChatSession();

    final wrongFrom = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: 'did:wrong:alice',
      body: {'text': 'Should fail'},
    );

    expect(
      () => aliceChatSDK.sendMessage(wrongFrom),
      throwsA(isA<Exception>()),
    );

    final wrongTo = PlainTextMessage(
      id: 'group-test-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      to: ['did:wrong:group'],
      body: {'text': 'Should fail'},
    );

    expect(() => aliceChatSDK.sendMessage(wrongTo), throwsA(isA<Exception>()));
  });

  test('group sendMessage with notify flag delivers message', () async {
    await aliceChatSDK.startChatSession();
    await bobChatSDK.startChatSession();

    final bobCompleter = Completer<PlainTextMessage>();

    final chatStream = await bobChatSDK.chatStreamSubscription;
    chatStream!.listen((data) {
      if (data.plainTextMessage?.type.toString() ==
          ChatProtocol.chatMessage.value) {
        if (data.plainTextMessage?.body?['text'] == 'Notify group test' &&
            !bobCompleter.isCompleted) {
          bobCompleter.complete(data.plainTextMessage!);
          chatStream.dispose();
        }
      }
    });

    final message = PlainTextMessage(
      id: 'group-notify-id',
      type: Uri.parse(ChatProtocol.chatMessage.value),
      from: groupOwnerDidDocument.id,
      to: [publishOfferResult.connectionOffer.groupDid!],
      body: {
        'text': 'Notify group test',
        'seq_no': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await aliceChatSDK.sendMessage(message, notify: true);

    final received = await bobCompleter.future;
    expect(received.body!['text'], equals('Notify group test'));
    expect(received.from, equals(groupOwnerDidDocument.id));
    expect(
      received.to?.first,
      equals(publishOfferResult.connectionOffer.groupDid!),
    );
    expect(received.id, equals('group-notify-id'));
  });
}
