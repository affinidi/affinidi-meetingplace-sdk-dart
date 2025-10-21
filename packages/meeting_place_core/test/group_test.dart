import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/v_card.dart';
import 'utils/discovery_test_utils.dart';
import 'utils/sdk.dart';

void main() async {
  /**
   * TODO: test cases
   * - check if Alice updates group internally
   * - check if Alice updates connection offer internally
   */
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;
  late MeetingPlaceCoreSDK charlieSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
    charlieSDK = await initSDKInstance();
  });

  test('offer creation for group', () async {
    final metadata = 'foobar';
    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.groupInvitation,
      metadata: metadata,
    );

    expect(result, isNotNull);
    expect(result.connectionOffer, isA<GroupConnectionOffer>());
    expect(result.publishedOfferDidManager, isA<DidManager>());
    expect(result.connectionOffer.groupId, isNotNull);
    expect(result.connectionOffer.metadata, metadata);
  });

  test('accept offer for group', () async {
    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.groupInvitation,
      metadata: 'foobar',
    );

    final actual = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    expect(actual, isA<AcceptOfferResult>());
    expect(actual.connectionOffer.acceptOfferDid, isNotNull);
    expect(actual.connectionOffer.permanentChannelDid, isNotNull);
  });

  test('alice receives notification about acceptance for group', () async {
    var receivedEvent = false;
    await aliceSDK.deleteDiscoveryEvents();

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.groupInvitation,
      metadata: 'foobar',
    );

    final acceptOfferResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptOfferResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final completer = Completer<void>();

    aliceSDK.controlPlaneEventsStream.listen((e) {
      if (e.type == ControlPlaneEventType.InvitationGroupAccept) {
        receivedEvent = true;
        completer.complete();
      }
    });

    await aliceSDK.processControlPlaneEvents();
    await completer.future;
    expect(receivedEvent, equals(true));
  });

  test(
    '''alice updates group on edge device to have one admin (=alice) and a member(=bob)''',
    () async {
      await aliceSDK.deleteDiscoveryEvents();

      final aliceVCard = VCardFixture.alicePrimaryVCard;
      final bobVCard = VCardFixture.bobPrimaryVCard;

      final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
        offerName: 'Sample offer',
        vCard: aliceVCard,
        type: SDKConnectionOfferType.groupInvitation,
        metadata: 'foobar',
      );

      final acceptResult = await bobSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        vCard: bobVCard,
      );

      await bobSDK.notifyAcceptance(
        connectionOffer: acceptResult.connectionOffer,
        senderInfo: 'Bob',
      );

      final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
        aliceSDK,
        eventType: ControlPlaneEventType.InvitationGroupAccept,
        expectedNumberOfEvents: 1,
      );

      await aliceSDK.processControlPlaneEvents();
      await aliceCompleter.future;

      final approved = await aliceSDK.getConnectionOffer(
        result.connectionOffer.offerLink,
      );

      final channel = await aliceSDK.getChannelByDid(
        result.connectionOffer.groupDid!,
      );

      await aliceSDK.approveConnectionRequest(
        connectionOffer: approved!,
        channel: channel!,
      );

      final group = await aliceSDK.getGroupByOfferLink(
        result.connectionOffer.offerLink,
      );

      // general assertions
      expect(group!.members.length, equals(2));
      expect(group.did, result.connectionOffer.groupDid);
      expect(group.ownerDid, result.connectionOffer.groupOwnerDid);
      expect(group.offerLink, result.connectionOffer.offerLink);

      // admin assertions
      final aliceAdmin = group.members.first;
      expect(aliceAdmin.membershipType, equals(GroupMembershipType.admin));
      expect(aliceAdmin.status, equals(GroupMemberStatus.approved));
      expect(aliceAdmin.vCard.values, equals(aliceVCard.values));
      expect(aliceAdmin.did, equals(result.connectionOffer.groupOwnerDid));

      // member assertions
      final bobMember = group.members[1];
      expect(bobMember.membershipType, equals(GroupMembershipType.member));
      expect(bobMember.status, equals(GroupMemberStatus.approved));
      expect(
        bobMember.did,
        equals(acceptResult.connectionOffer.permanentChannelDid),
      );
      expect(bobMember.vCard.values, equals(bobVCard.values));

      aliceSDK.disposeDiscoveryEventsStream();
    },
  );

  test(
    '''Group admin approves membership request -> ACLS getting updated and group details update message is sent''',
    () async {
      final aliceVCard = VCardFixture.alicePrimaryVCard;
      final bobVCard = VCardFixture.bobPrimaryVCard;

      PlainTextMessage useChatMessage(String from, String to) =>
          PlainTextMessage(
            id: Uuid().v4(),
            type: Uri.parse('https://affinidi.io/mpx/core-sdk/test'),
            from: from,
            to: [to],
            body: {'text': '[integration test]: Checking ACL!'},
          );

      final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
        offerName: 'Sample offer',
        vCard: aliceVCard,
        type: SDKConnectionOfferType.groupInvitation,
      );

      final acceptResultBob = await bobSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        vCard: bobVCard,
      );

      await bobSDK.notifyAcceptance(
        connectionOffer: acceptResultBob.connectionOffer,
        senderInfo: 'Bob',
      );

      final acceptResultCharlie = await charlieSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        vCard: VCardFixture.charliePrimaryVCard,
      );

      await charlieSDK.notifyAcceptance(
        connectionOffer: acceptResultCharlie.connectionOffer,
        senderInfo: 'Charlie',
      );

      final groupDid = result.connectionOffer.groupDid!;
      final groupOwnerDidDoc =
          await result.groupOwnerDidManager!.getDidDocument();

      // --- Check that ACLs are not updated yet
      expect(
          () => bobSDK.sendMessage(
                useChatMessage(
                  acceptResultBob.connectionOffer.permanentChannelDid!,
                  groupDid,
                ),
                senderDid: acceptResultBob.connectionOffer.permanentChannelDid!,
                recipientDid: groupDid,
              ),
          throwsA(isA<MeetingPlaceCoreSDKException>()));

      expect(
          () => bobSDK.sendMessage(
                useChatMessage(
                  acceptResultBob.connectionOffer.permanentChannelDid!,
                  groupOwnerDidDoc.id,
                ),
                senderDid: acceptResultBob.connectionOffer.permanentChannelDid!,
                recipientDid: groupOwnerDidDoc.id,
              ),
          throwsA(isA<MeetingPlaceCoreSDKException>()));
      // --- [OK] ACLs not set

      final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
        aliceSDK,
        eventType: ControlPlaneEventType.InvitationGroupAccept,
        expectedNumberOfEvents: 2,
      );

      // Execute event handlers in the background
      await aliceSDK.processControlPlaneEvents();
      await aliceCompleter.future;

      final charlieDidDoc =
          await acceptResultCharlie.permanentChannelDid.getDidDocument();
      final charlieChannel = await aliceSDK.getChannelByDid(charlieDidDoc.id);

      await aliceSDK.approveConnectionRequest(
        connectionOffer: result.connectionOffer,
        channel: charlieChannel!,
      );

      final charlieCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
        charlieSDK,
        eventType: ControlPlaneEventType.GroupMembershipFinalised,
        expectedNumberOfEvents: 1,
      );

      await charlieSDK.processControlPlaneEvents();
      await charlieCompleter.future;

      final acceptResultBobChannelDid =
          await acceptResultBob.permanentChannelDid.getDidDocument();

      final bobChannel = await aliceSDK.getChannelByDid(
        acceptResultBobChannelDid.id,
      );

      await aliceSDK.approveConnectionRequest(
        connectionOffer: result.connectionOffer,
        channel: bobChannel!,
      );

      await bobSDK.processControlPlaneEvents();
      // await charlieWaitForChatGroupDetailsUpdate.future;

      // Verify that chat group contacts details update was sent
      // TODO: move this test case to chat SDK because responsibility has changed
      // expect(receivedChatGroupDetailsUpdateMessage, isNotNull);
      // expect(
      //   receivedChatGroupDetailsUpdateMessage
      //       .body?['group_message']['members'][1]['status'],
      //   equals('approved'),
      // );

      // Verify that ACLs are configured correctly
      expect(
        bobSDK.sendMessage(
          useChatMessage(acceptResultBobChannelDid.id, groupDid),
          senderDid: acceptResultBobChannelDid.id,
          recipientDid: groupDid,
        ),
        completes,
      );

      expect(
        bobSDK.sendMessage(
          useChatMessage(acceptResultBobChannelDid.id, groupOwnerDidDoc.id),
          senderDid: acceptResultBobChannelDid.id,
          recipientDid: groupOwnerDidDoc.id,
        ),
        completes,
      );

      expect(
        charlieSDK.sendMessage(
          useChatMessage(charlieDidDoc.id, groupDid),
          senderDid: charlieDidDoc.id,
          recipientDid: groupDid,
        ),
        completes,
      );

      expect(
        charlieSDK.sendMessage(
          useChatMessage(charlieDidDoc.id, groupOwnerDidDoc.id),
          senderDid: charlieDidDoc.id,
          recipientDid: groupOwnerDidDoc.id,
        ),
        completes,
      );
    },
  );

  test('Member receives group membership finalied discovery event', () async {
    final aliceVCard = VCardFixture.alicePrimaryVCard;
    final bobVCard = VCardFixture.bobPrimaryVCard;

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: aliceVCard,
      type: SDKConnectionOfferType.groupInvitation,
    );

    final groupDidDocument = await UniversalDIDResolver().resolveDid(
      result.connectionOffer.groupDid!,
    );
    final senderDidDocument =
        await result.groupOwnerDidManager!.getDidDocument();

    final chatMessage = PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse('https://affinidi.io/mpx/core-sdk/test'),
      from: senderDidDocument.id,
      to: [groupDidDocument.id],
      body: {'text': '[integration test]: Checking ACL!'},
    );

    await aliceSDK.sendGroupMessage(
      chatMessage,
      senderDid: result.connectionOffer.groupOwnerDid!,
      recipientDid: groupDidDocument.id,
      increaseSequenceNumber: true,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      vCard: bobVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final publishOfferDidDoc =
        await result.publishedOfferDidManager.getDidDocument();

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(
      connectionOffer: result.connectionOffer,
      channel: channel!,
    );

    final group = await aliceSDK.getGroupByOfferLink(
      result.connectionOffer.offerLink,
    );

    final messages = await bobSDK.fetchMessages(
      did: acceptResult.connectionOffer.permanentChannelDid!,
    );

    final actual = messages.firstWhereOrNull(
      (m) =>
          m.plainTextMessage.type.toString() ==
              MeetingPlaceProtocol.groupMemberInauguration.value &&
          m.plainTextMessage.from == publishOfferDidDoc.id,
    );

    expect(actual, isNotNull);
    expect(
      actual!.plainTextMessage.body?['memberDid'],
      acceptResult.connectionOffer.permanentChannelDid!,
    );

    // assert group information
    expect(actual.plainTextMessage.body?['groupDid'], group!.did);
    expect(actual.plainTextMessage.body?['groupPublicKey'], group.publicKey);

    final bobCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      bobSDK,
      eventType: ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    await bobSDK.processControlPlaneEvents();

    final newActual = await bobSDK.getConnectionOffer(
      result.connectionOffer.offerLink,
    );

    expect(newActual!.status, ConnectionOfferStatus.finalised);

    // Check channel.seqNo of joined member - there was one group message before
    final updatedChannel = await bobSDK.getChannelByDid(
      acceptResult.connectionOffer.permanentChannelDid!,
    );
    expect(updatedChannel!.seqNo, 1);

    // TODO: assert members
  });

  test('Member has been approved', () async {
    final aliceVCard = VCardFixture.alicePrimaryVCard;
    final bobVCard = VCardFixture.bobPrimaryVCard;

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      type: SDKConnectionOfferType.groupInvitation,
      vCard: aliceVCard,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      vCard: bobVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(
      connectionOffer: result.connectionOffer,
      channel: channel!,
    );

    final group = await aliceSDK.getGroupByOfferLink(
      result.connectionOffer.offerLink,
    );
    final actual = group!.members.firstWhere(
      (member) =>
          member.did == acceptResult.connectionOffer.permanentChannelDid!,
    );

    expect(actual.status, GroupMemberStatus.approved);
  });

  test('Member leaves group', () async {
    // TODO: check ACLs
    final aliceVCard = VCardFixture.alicePrimaryVCard;
    final bobVCard = VCardFixture.bobPrimaryVCard;

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: aliceVCard,
      validUntil: DateTime.now().toUtc().add(const Duration(seconds: 60)),
      type: SDKConnectionOfferType.groupInvitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: result.connectionOffer.mnemonic,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: bobVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final acceptConnectionOffer =
        acceptResult.connectionOffer as GroupConnectionOffer;

    final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(
      connectionOffer: result.connectionOffer,
      channel: channel!,
    );

    final bobCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      bobSDK,
      eventType: ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    final bobMemberDidDic =
        await acceptResult.permanentChannelDid.getDidDocument();

    final bobChannel = await bobSDK.getChannelByDid(bobMemberDidDic.id);

    await bobSDK.leaveChannel(bobChannel!);
    final groupExp = await bobSDK.getGroupById(acceptConnectionOffer.groupId);

    final connectionExp = await bobSDK.getConnectionOffer(
      acceptResult.connectionOffer.offerLink,
    );

    expect(groupExp, isNull);
    expect(connectionExp!.status, equals(ConnectionOfferStatus.deleted));

    expect(
      () => aliceSDK.sendMessage(
        PlainTextMessage(
          id: Uuid().v4(),
          type: Uri.parse('https://affinidi.io/mpx/core-sdk/test'),
          from: result.connectionOffer.groupDid,
          to: [acceptConnectionOffer.memberDid!],
          body: {'text': 'Not allowed'},
        ),
        senderDid: result.connectionOffer.groupDid!,
        recipientDid: acceptConnectionOffer.memberDid!,
      ),
      throwsA(isA<MeetingPlaceCoreSDKException>()),
    );
  });

  test('Admin leaves group', () async {
    // TODO: check ACLs
    final aliceVCard = VCardFixture.alicePrimaryVCard;
    final bobVCard = VCardFixture.bobPrimaryVCard;

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      vCard: aliceVCard,
      type: SDKConnectionOfferType.groupInvitation,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      vCard: bobVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final aliceCompleter = DiscoveryTestUtils.waitForDiscoveryEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(
      connectionOffer: result.connectionOffer,
      channel: channel!,
    );

    await bobSDK.processControlPlaneEvents();

    final aliceMemberDidDoc =
        await result.groupOwnerDidManager!.getDidDocument();

    final aliceChannel = await aliceSDK.getChannelByDid(aliceMemberDidDoc.id);
    await aliceSDK.leaveChannel(aliceChannel!);

    final groupExp = await aliceSDK.getGroupById(
      acceptResult.connectionOffer.groupId,
    );

    final expConnectionOffer = await aliceSDK.getConnectionOffer(
      result.connectionOffer.offerLink,
    );
    final expChannel = await aliceSDK.getChannelByDid(aliceMemberDidDoc.id);

    // Verify that connection offer has been marked as deleted
    expect(expConnectionOffer?.status, equals(ConnectionOfferStatus.deleted));

    // Verify that connection offer has been deregistered from meeting place
    expect(
        () => aliceSDK.findOffer(mnemonic: result.connectionOffer.mnemonic),
        throwsA(
          predicate((e) =>
              e is MeetingPlaceCoreSDKException &&
              e.code ==
                  MeetingPlaceCoreSDKErrorCode
                      .connectionOfferNotFoundError.value),
        ));

    // Verify group and channel entities have been deleted
    expect(groupExp, isNull);
    expect(expChannel, isNull);
  });

  // TODO: Check if ephemeral messages getting deleted
}
