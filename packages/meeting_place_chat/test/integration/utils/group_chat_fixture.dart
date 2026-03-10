import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../../utils/contact_card_fixture.dart';
import '../../utils/control_plane_test_utils.dart';
import '../../utils/sdk.dart';

class GroupChatFixture {
  GroupChatFixture._();

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

  static Future<GroupChatFixture> create() async {
    final fixture = GroupChatFixture._();

    fixture.aliceChannelRepository = initChannelRepository();
    fixture.bobChannelRepository = initChannelRepository();
    fixture.charlieChannelRepository = initChannelRepository();

    fixture.aliceSDK = await initCoreSDKInstance();
    fixture.bobSDK = await initCoreSDKInstance();
    fixture.charlieSDK = await initCoreSDKInstance();

    fixture.publishOfferResult = await fixture.aliceSDK
        .publishOffer<GroupConnectionOffer>(
          offerName: 'Sample offer',
          offerDescription: 'Sample offer description',
          contactCard: ContactCardFixture.getContactCardFixture(
            did: 'did:test:alice',
            contactInfo: ContactCardFixture.alicePrimaryCardInfo,
          ),
          type: SDKConnectionOfferType.groupInvitation,
        );

    fixture.groupOwnerDidDocument = await fixture
        .publishOfferResult
        .groupOwnerDidManager!
        .getDidDocument();

    final bobFindOfferResult = await fixture.bobSDK.findOffer(
      mnemonic: fixture.publishOfferResult.connectionOffer.mnemonic,
    );
    final bobAcceptance = await fixture.bobSDK.acceptOffer(
      connectionOffer: bobFindOfferResult.connectionOffer!,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: ContactCardFixture.bobPrimaryCardInfo,
      ),
      senderInfo: 'Bob',
    );

    final charlieFindOfferResult = await fixture.charlieSDK.findOffer(
      mnemonic: fixture.publishOfferResult.connectionOffer.mnemonic,
    );
    final charlieAcceptance = await fixture.charlieSDK.acceptOffer(
      connectionOffer: charlieFindOfferResult.connectionOffer!,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:charlie',
        contactInfo: ContactCardFixture.charliePrimaryCardInfo,
      ),
      senderInfo: 'Charlie',
    );

    fixture.bobMemberDid =
        (bobAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;
    fixture.charlieMemberDid =
        (charlieAcceptance.connectionOffer as GroupConnectionOffer).memberDid!;

    final aliceSDKCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      fixture.aliceSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.InvitationGroupAccept &&
          event.channel.otherPartyPermanentChannelDid ==
              fixture.publishOfferResult.connectionOffer.groupDid,
      expectedNumberOfEvents: 2,
    );

    await fixture.aliceSDK.processControlPlaneEvents();
    await aliceSDKCompleter.future;

    final bobChannel = await fixture.aliceSDK.getChannelByDid(
      fixture.bobMemberDid,
    );
    final charlieChannel = await fixture.aliceSDK.getChannelByDid(
      fixture.charlieMemberDid,
    );

    await fixture.aliceSDK.approveConnectionRequest(channel: bobChannel!);
    await fixture.aliceSDK.approveConnectionRequest(channel: charlieChannel!);

    final bobCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      fixture.bobSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );
    await fixture.bobSDK.processControlPlaneEvents();
    await bobCompleter.future;

    final charlieCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      fixture.charlieSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.GroupMembershipFinalised,
      expectedNumberOfEvents: 1,
    );
    await fixture.charlieSDK.processControlPlaneEvents();
    await charlieCompleter.future;

    fixture.aliceGroup = (await fixture.aliceSDK.getGroupByOfferLink(
      fixture.publishOfferResult.connectionOffer.offerLink,
    ))!;

    fixture.aliceChatSDK = await initGroupChatSDK(
      coreSDK: fixture.aliceSDK,
      did: fixture.groupOwnerDidDocument.id,
      otherPartyDid: fixture.publishOfferResult.connectionOffer.groupDid!,
      group: fixture.aliceGroup,
      channelRepository: fixture.aliceChannelRepository,
    );

    fixture.bobGroup = (await fixture.bobSDK.getGroupByOfferLink(
      fixture.publishOfferResult.connectionOffer.offerLink,
    ))!;

    fixture.bobChatSDK = await initGroupChatSDK(
      coreSDK: fixture.bobSDK,
      did: fixture.bobMemberDid,
      otherPartyDid: fixture.publishOfferResult.connectionOffer.groupDid!,
      group: fixture.bobGroup,
      channelRepository: fixture.bobChannelRepository,
    );

    fixture.charlieGroup = (await fixture.charlieSDK.getGroupByOfferLink(
      fixture.publishOfferResult.connectionOffer.offerLink,
    ))!;

    fixture.charlieChatSDK = await initGroupChatSDK(
      coreSDK: fixture.charlieSDK,
      did: fixture.charlieMemberDid,
      otherPartyDid: fixture.publishOfferResult.connectionOffer.groupDid!,
      group: fixture.charlieGroup,
      channelRepository: fixture.charlieChannelRepository,
    );

    return fixture;
  }

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

  void disposeSessions() {
    aliceChatSDK.endChatSession();
    bobChatSDK.endChatSession();
    charlieChatSDK.endChatSession();
  }
}
