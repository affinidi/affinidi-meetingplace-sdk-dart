import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/contact_card_fixture.dart';
import 'utils/control_plane_test_utils.dart';
import 'utils/sdk.dart';

void main() async {
  final messageType = Uri.parse('https://affinidi.io/mpx/core-sdk/test');

  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;
  late MeetingPlaceCoreSDK charlieSDK;

  late String aliceDid;
  late String bobDid;
  late String charlieDid;
  late String groupDid;

  setUpAll(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
    charlieSDK = await initSDKInstance();

    // Setup group
    final aliceCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    );
    final bobCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );
    final charlieCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:charlie',
      contactInfo: {
        'n': {'given': 'Charlie', 'surname': 'A.'},
      },
    );

    final publishOfferResult = await aliceSDK
        .publishOffer<GroupConnectionOffer>(
          offerName: 'Sample offer',
          offerDescription: 'Sample offer description',
          contactCard: aliceCard,
          type: SDKConnectionOfferType.groupInvitation,
        );

    final bobAcceptance = await bobSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final charlieAcceptance = await charlieSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      contactCard: charlieCard,
      senderInfo: 'Bob',
    );

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

    final bobMemberDidDoc = await bobAcceptance.permanentChannelDid
        .getDidDocument();
    final aliceToBobChannel = await aliceSDK.getChannelByOtherPartyPermanentDid(
      bobMemberDidDoc.id,
    );

    // Alice approves Bob's group membership request
    await aliceSDK.approveConnectionRequest(channel: aliceToBobChannel!);

    final charlieMemberDidDoc = await charlieAcceptance.permanentChannelDid
        .getDidDocument();
    final aliceToCharlieChannel = await aliceSDK
        .getChannelByOtherPartyPermanentDid(charlieMemberDidDoc.id);

    // Alice approves Charlie's group membership request
    await aliceSDK.approveConnectionRequest(channel: aliceToCharlieChannel!);

    // Run event handlers in background for Bob and Charlie -> ready to chat
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

    aliceDid = publishOfferResult.connectionOffer.groupOwnerDid!;
    bobDid = bobAcceptance.connectionOffer.permanentChannelDid!;
    charlieDid = charlieAcceptance.connectionOffer.permanentChannelDid!;
    groupDid = publishOfferResult.connectionOffer.groupDid!;
  });

  test('group admin sends group message', () async {
    final messageId = const Uuid().v4();
    final chatMessage = PlainTextMessage(
      id: messageId,
      type: messageType,
      from: aliceDid,
      to: [groupDid],
      body: {'text': 'Hello Group!', 'seq_no': 1},
    );

    final bobStream = await bobSDK.subscribeToMediator(bobDid);
    final charlieStream = await charlieSDK.subscribeToMediator(charlieDid);

    final bobReceivedMessageCompleter = Completer<PlainTextMessage>();
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    // Listeners filter for specific type and sequence number to avoid test
    // flakiness in case messages from previous test are received because
    // they run in parallel and use same group
    bobStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 1) {
        bobReceivedMessageCompleter.complete(data.plainTextMessage);
        bobStream.dispose();
      }
    });

    charlieStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 1) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
        charlieStream.dispose();
      }
    });

    // Delay to ensure ACLs have been setup for the group before sending the
    // message, otherwise message might not be delivered to members
    await Future.delayed(const Duration(seconds: 3));

    await aliceSDK.sendGroupMessage(
      chatMessage,
      senderDid: aliceDid,
      recipientDid: groupDid,
      increaseSequenceNumber: true,
    );

    final bobReceivedMessage = await bobReceivedMessageCompleter.future;
    expect(bobReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(bobReceivedMessage.body!['seq_no'], equals(1));

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seq_no'], equals(1));
  });

  test('group member sends group message', () async {
    final chatMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: messageType,
      from: bobDid,
      to: [groupDid],
      body: {'text': 'Hello Group!', 'seq_no': 2},
      attachments: [],
    );

    // Subscribe Alice and Charlie to mediator WebSocket to receive group
    // messages before sending the message, otherwise message might not be
    // delivered to them
    final aliceStream = await aliceSDK.subscribeToMediator(aliceDid);
    final aliceReceivedMessageCompleter = Completer<PlainTextMessage>();

    final charlieStream = await charlieSDK.subscribeToMediator(charlieDid);
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    // Listeners filter for specific type and sequence number to avoid test
    // flakiness in case messages from previous test are received because
    // they run in parallel and use same group
    aliceStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 2) {
        aliceReceivedMessageCompleter.complete(data.plainTextMessage);
        aliceStream.dispose();
      }
    });

    charlieStream.stream.listen((data) {
      if (data.plainTextMessage.type == messageType &&
          data.plainTextMessage.body?['seq_no'] == 2) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
        charlieStream.dispose();
      }
    });

    await bobSDK.sendGroupMessage(
      chatMessage,
      senderDid: bobDid,
      recipientDid: groupDid,
      increaseSequenceNumber: true,
    );

    final aliceReceivedMessage = await aliceReceivedMessageCompleter.future;
    expect(aliceReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(aliceReceivedMessage.body!['seq_no'], equals(2));

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seq_no'], equals(2));
  });
}
