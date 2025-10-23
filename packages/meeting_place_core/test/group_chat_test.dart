import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/v_card.dart';
import 'utils/contrpl_plane_test_utils.dart';
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
    final aliceVCard = VCardFixture.alicePrimaryVCard;
    final bobVCard = VCardFixture.bobPrimaryVCard;
    final charlieVCard = VCardFixture.charliePrimaryVCard;

    final publishOfferResult =
        await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: aliceVCard,
      type: SDKConnectionOfferType.groupInvitation,
    );

    final bobAcceptance = await bobSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      vCard: bobVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: bobAcceptance.connectionOffer,
      senderInfo: 'Bob',
    );

    final charlieAcceptance = await charlieSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      vCard: charlieVCard,
    );

    await charlieSDK.notifyAcceptance(
      connectionOffer: charlieAcceptance.connectionOffer,
      senderInfo: 'Charlie',
    );

    final aliceSDKCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 2,
    );

    // Execute event handlers in the background for Alice
    await aliceSDK.processControlPlaneEvents();
    await aliceSDKCompleter.future;

    final bobMemberDidDoc =
        await bobAcceptance.permanentChannelDid.getDidDocument();
    final aliceToBobChannel = await aliceSDK.getChannelByOtherPartyPermanentDid(
      bobMemberDidDoc.id,
    );

    // Alice approves Bob's group membership request
    await aliceSDK.approveConnectionRequest(
      connectionOffer: publishOfferResult.connectionOffer,
      channel: aliceToBobChannel!,
    );

    final charlieMemberDidDoc =
        await charlieAcceptance.permanentChannelDid.getDidDocument();
    final aliceToCharlieChannel = await aliceSDK
        .getChannelByOtherPartyPermanentDid(charlieMemberDidDoc.id);

    // Alice approves Charlie's group membership request
    await aliceSDK.approveConnectionRequest(
      connectionOffer: publishOfferResult.connectionOffer,
      channel: aliceToCharlieChannel!,
    );

    // Run event handlers in background for Bob and Charlie -> ready to chat
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

    aliceDid = publishOfferResult.connectionOffer.groupOwnerDid!;
    bobDid = bobAcceptance.connectionOffer.permanentChannelDid!;
    charlieDid = charlieAcceptance.connectionOffer.permanentChannelDid!;
    groupDid = publishOfferResult.connectionOffer.groupDid!;
  });

  test('group admin sends group message', () async {
    final chatMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: messageType,
      from: aliceDid,
      to: [groupDid],
      body: {'text': 'Hello Group!', 'seqNo': 1},
    );

    final bobStream = await bobSDK.subscribeToMediator(bobDid);
    final charlieStream = await charlieSDK.subscribeToMediator(charlieDid);

    final bobReceivedMessageCompleter = Completer<PlainTextMessage>();
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    bobStream.listen((data) {
      if (data.plainTextMessage.type == messageType) {
        bobReceivedMessageCompleter.complete(data.plainTextMessage);
      }
    });

    charlieStream.listen((data) {
      if (data.plainTextMessage.type == messageType) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
      }
    });

    await aliceSDK.sendGroupMessage(
      chatMessage,
      senderDid: aliceDid,
      recipientDid: groupDid,
      increaseSequenceNumber: true,
    );

    final bobReceivedMessage = await bobReceivedMessageCompleter.future;
    expect(bobReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(bobReceivedMessage.body!['seqNo'], equals(1));

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seqNo'], equals(1));
  });

  test('group member sends group message', () async {
    final vCardBase64 = VCard(
      values: VCardFixture.bobPrimaryVCard.values,
    ).toBase64();

    final chatMessage = PlainTextMessage(
      id: const Uuid().v4(),
      type: messageType,
      from: bobDid,
      to: [groupDid],
      body: {'text': 'Hello Group!', 'seqNo': 2},
      attachments: [
        VCardAttachment.create(data: AttachmentData(base64: vCardBase64)),
      ],
    );

    final aliceStream = await aliceSDK.subscribeToMediator(aliceDid);
    final charlieStream = await charlieSDK.subscribeToMediator(charlieDid);

    final aliceReceivedMessageCompleter = Completer<PlainTextMessage>();
    final charlieReceivedMessageCompleter = Completer<PlainTextMessage>();

    aliceStream.listen((data) {
      if (data.plainTextMessage.type == messageType) {
        aliceReceivedMessageCompleter.complete(data.plainTextMessage);
      }
    });

    charlieStream.listen((data) {
      if (data.plainTextMessage.type == messageType) {
        charlieReceivedMessageCompleter.complete(data.plainTextMessage);
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
    expect(aliceReceivedMessage.body!['seqNo'], equals(2));
    expect(
      aliceReceivedMessage.attachments?[0].data?.base64,
      equals(vCardBase64),
    );

    final charlieReceivedMessage = await charlieReceivedMessageCompleter.future;
    expect(charlieReceivedMessage.body!['text'], equals('Hello Group!'));
    expect(charlieReceivedMessage.body!['seqNo'], equals(2));
    expect(
      charlieReceivedMessage.attachments?[0].data?.base64,
      equals(vCardBase64),
    );
  });
}
