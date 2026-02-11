import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/contact_card_fixture.dart';
import 'utils/control_plane_test_utils.dart';
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
      offerDescription: 'Sample offer description',
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
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
      offerDescription: 'Sample offer description',
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
      type: SDKConnectionOfferType.groupInvitation,
      metadata: 'foobar',
    );

    final actual = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: {
          'n': {'given': 'Bob', 'surname': 'A.'},
        },
      ),
      senderInfo: 'Bob',
    );

    expect(actual, isA<AcceptOfferResult>());
    expect(actual.connectionOffer.acceptOfferDid, isNotNull);
    expect(actual.connectionOffer.permanentChannelDid, isNotNull);
  });

  test('alice receives notification about acceptance for group', () async {
    var receivedEvent = false;
    await aliceSDK.deleteControlPlaneEvents();

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
      type: SDKConnectionOfferType.groupInvitation,
      metadata: 'foobar',
    );

    await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: {
          'n': {'given': 'Bob', 'surname': 'A.'},
        },
      ),
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
      await aliceSDK.deleteControlPlaneEvents();

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

      final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
        offerName: 'Sample offer',
        offerDescription: 'Sample offer description',
        contactCard: aliceCard,
        type: SDKConnectionOfferType.groupInvitation,
        metadata: 'foobar',
      );

      final acceptResult = await bobSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        contactCard: bobCard,
        senderInfo: 'Bob',
      );

      final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
        aliceSDK,
        eventType: ControlPlaneEventType.InvitationGroupAccept,
        expectedNumberOfEvents: 1,
      );

      await aliceSDK.processControlPlaneEvents();
      await aliceCompleter.future;

      final channel = await aliceSDK.getChannelByDid(
        result.connectionOffer.groupDid!,
      );

      await aliceSDK.approveConnectionRequest(channel: channel!);

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
      expect(aliceAdmin.contactCard.contactInfo, equals(aliceCard.contactInfo));
      expect(aliceAdmin.did, equals(result.connectionOffer.groupOwnerDid));

      // member assertions
      final bobMember = group.members[1];
      expect(bobMember.membershipType, equals(GroupMembershipType.member));
      expect(bobMember.status, equals(GroupMemberStatus.approved));
      expect(
        bobMember.did,
        equals(acceptResult.connectionOffer.permanentChannelDid),
      );
      expect(bobMember.contactCard.contactInfo, equals(bobCard.contactInfo));

      aliceSDK.disposeControlPlaneEventsStream();
    },
  );

  test(
    '''Group admin approves membership request -> ACLS getting updated and group details update message is sent''',
    () async {
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
        offerDescription: 'Sample offer description',
        contactCard: aliceCard,
        type: SDKConnectionOfferType.groupInvitation,
      );

      final acceptResultBob = await bobSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        contactCard: bobCard,
        senderInfo: 'Bob',
      );

      final acceptResultCharlie = await charlieSDK.acceptOffer(
        connectionOffer: result.connectionOffer,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test:charlie',
          contactInfo: {
            'n': {'given': 'Charlie', 'surname': 'A.'},
          },
        ),
        senderInfo: 'Bob',
      );

      final groupDid = result.connectionOffer.groupDid!;
      final groupOwnerDidDoc = await result.groupOwnerDidManager!
          .getDidDocument();

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
        throwsA(isA<MeetingPlaceCoreSDKException>()),
      );

      expect(
        () => bobSDK.sendMessage(
          useChatMessage(
            acceptResultBob.connectionOffer.permanentChannelDid!,
            groupOwnerDidDoc.id,
          ),
          senderDid: acceptResultBob.connectionOffer.permanentChannelDid!,
          recipientDid: groupOwnerDidDoc.id,
        ),
        throwsA(isA<MeetingPlaceCoreSDKException>()),
      );
      // --- [OK] ACLs not set

      final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
        aliceSDK,
        eventType: ControlPlaneEventType.InvitationGroupAccept,
        expectedNumberOfEvents: 2,
      );

      // Execute event handlers in the background
      await aliceSDK.processControlPlaneEvents();
      await aliceCompleter.future;

      final charlieDidDoc = await acceptResultCharlie.permanentChannelDid
          .getDidDocument();
      final charlieChannel = await aliceSDK.getChannelByDid(charlieDidDoc.id);

      await aliceSDK.approveConnectionRequest(channel: charlieChannel!);

      final charlieCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
        charlieSDK,
        eventType: ControlPlaneEventType.GroupMembershipFinalised,
        expectedNumberOfEvents: 1,
      );

      await charlieSDK.processControlPlaneEvents();
      await charlieCompleter.future;

      final acceptResultBobChannelDid = await acceptResultBob
          .permanentChannelDid
          .getDidDocument();

      final bobChannel = await aliceSDK.getChannelByDid(
        acceptResultBobChannelDid.id,
      );

      await aliceSDK.approveConnectionRequest(channel: bobChannel!);

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

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: aliceCard,
      type: SDKConnectionOfferType.groupInvitation,
    );

    final groupDidDocument = await UniversalDIDResolver().resolveDid(
      result.connectionOffer.groupDid!,
    );
    final senderDidDocument = await result.groupOwnerDidManager!
        .getDidDocument();

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
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final publishOfferDidDoc = await result.publishedOfferDidManager
        .getDidDocument();

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(channel: channel!);

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
      actual!.plainTextMessage.body?['member_did'],
      acceptResult.connectionOffer.permanentChannelDid!,
    );

    // assert group information
    expect(actual.plainTextMessage.body?['group_did'], group!.did);
    expect(actual.plainTextMessage.body?['group_public_key'], group.publicKey);

    final bobCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
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

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      type: SDKConnectionOfferType.groupInvitation,
      contactCard: aliceCard,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(channel: channel!);

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

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: aliceCard,
      validUntil: DateTime.now().toUtc().add(const Duration(seconds: 60)),
      type: SDKConnectionOfferType.groupInvitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: result.connectionOffer.mnemonic,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final acceptConnectionOffer =
        acceptResult.connectionOffer as GroupConnectionOffer;

    final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(channel: channel!);

    final bobCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      bobSDK,
      eventType: ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );

    await bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    final bobMemberDidDic = await acceptResult.permanentChannelDid
        .getDidDocument();

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

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: aliceCard,
      type: SDKConnectionOfferType.groupInvitation,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final aliceCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      aliceSDK,
      eventType: ControlPlaneEventType.InvitationGroupAccept,
      expectedNumberOfEvents: 1,
    );

    await aliceSDK.processControlPlaneEvents();
    await aliceCompleter.future;

    final channel = await aliceSDK.getChannelByDid(
      result.connectionOffer.groupDid!,
    );

    await aliceSDK.approveConnectionRequest(channel: channel!);

    await bobSDK.processControlPlaneEvents();

    final aliceMemberDidDoc = await result.groupOwnerDidManager!
        .getDidDocument();

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
        predicate(
          (e) =>
              e is MeetingPlaceCoreSDKException &&
              e.code ==
                  MeetingPlaceCoreSDKErrorCode
                      .connectionOfferNotFoundError
                      .value,
        ),
      ),
    );

    // Verify group and channel entities have been deleted
    expect(groupExp, isNull);
    expect(expChannel, isNull);
  });

  test('duplicate group acceptance results in one channel only', () async {
    await aliceSDK.deleteControlPlaneEvents();

    final result = await aliceSDK.publishOffer<GroupConnectionOffer>(
      offerName: 'Sample offer',
      offerDescription: 'Sample offer description',
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
      type: SDKConnectionOfferType.groupInvitation,
      metadata: 'foobar',
    );

    final bobContactCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );

    final acceptance = await bobSDK.acceptOffer(
      connectionOffer: result.connectionOffer,
      contactCard: bobContactCard,
      senderInfo: 'Bob',
    );

    // Manually send a duplicate acceptance message to simulate the case where
    // multiple acceptance messages are generated due to retries or other
    // reasons.
    final invitationAcceptanceMessage = InvitationAcceptanceGroup.create(
      from: acceptance.connectionOffer.acceptOfferDid!,
      to: [acceptance.connectionOffer.publishOfferDid],
      parentThreadId: result.connectionOffer.offerLink,
      channelDid: acceptance.connectionOffer.permanentChannelDid!,
      publicKey: '',
      contactCard: bobContactCard,
    );

    final recipientDidDocument = await bobSDK.didResolver.resolveDid(
      acceptance.connectionOffer.publishOfferDid,
    );

    await bobSDK.mediator.sendMessage(
      invitationAcceptanceMessage.toPlainTextMessage(),
      senderDidManager: acceptance.acceptOfferDid,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: acceptance.connectionOffer.mediatorDid,
      next: acceptance.connectionOffer.publishOfferDid,
    );

    final completer = Completer<Channel>();
    int receivedInvitationAcceptEvents = 0;

    aliceSDK.controlPlaneEventsStream.listen((e) {
      if (e.type == ControlPlaneEventType.InvitationGroupAccept) {
        receivedInvitationAcceptEvents++;
        completer.complete(e.channel);
      }
    });

    await aliceSDK.processControlPlaneEvents();
    expect(await completer.future, isA<Channel>());
    expect(receivedInvitationAcceptEvents, equals(1));
  });
}
