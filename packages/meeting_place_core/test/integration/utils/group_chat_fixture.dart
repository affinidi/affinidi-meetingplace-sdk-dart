import 'package:meeting_place_core/meeting_place_core.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/control_plane_test_utils.dart';
import '../../utils/sdk.dart';

class GroupChatFixture {
  GroupChatFixture._();

  late final MeetingPlaceCoreSDK aliceSDK;
  late final MeetingPlaceCoreSDK bobSDK;
  late final MeetingPlaceCoreSDK charlieSDK;

  late final String aliceDid;
  late final String bobDid;
  late final String charlieDid;
  late final String groupDid;

  static Future<GroupChatFixture> create() async {
    final fixture = GroupChatFixture._();

    fixture.aliceSDK = await initSDKInstance();
    fixture.bobSDK = await initSDKInstance();
    fixture.charlieSDK = await initSDKInstance();

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

    final publishOfferResult = await fixture.aliceSDK
        .publishOffer<GroupConnectionOffer>(
          offerName: 'Sample offer',
          offerDescription: 'Sample offer description',
          contactCard: aliceCard,
          type: SDKConnectionOfferType.groupInvitation,
        );

    final bobAcceptance = await fixture.bobSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    final charlieAcceptance = await fixture.charlieSDK.acceptOffer(
      connectionOffer: publishOfferResult.connectionOffer,
      contactCard: charlieCard,
      senderInfo: 'Bob',
    );

    final aliceSDKCompleter = ControlPlaneTestUtils.waitForControlPlaneEvent(
      fixture.aliceSDK,
      filter: (event) =>
          event.type == ControlPlaneEventType.InvitationGroupAccept &&
          event.channel.otherPartyPermanentChannelDid ==
              publishOfferResult.connectionOffer.groupDid,
      expectedNumberOfEvents: 2,
    );

    await fixture.aliceSDK.processControlPlaneEvents();
    await aliceSDKCompleter.future;

    final bobMemberDidDoc = await bobAcceptance.permanentChannelDid
        .getDidDocument();
    final aliceToBobChannel = await fixture.aliceSDK
        .getChannelByOtherPartyPermanentDid(bobMemberDidDoc.id);

    await fixture.aliceSDK.approveConnectionRequest(
      channel: aliceToBobChannel!,
    );

    final charlieMemberDidDoc = await charlieAcceptance.permanentChannelDid
        .getDidDocument();
    final aliceToCharlieChannel = await fixture.aliceSDK
        .getChannelByOtherPartyPermanentDid(charlieMemberDidDoc.id);

    await fixture.aliceSDK.approveConnectionRequest(
      channel: aliceToCharlieChannel!,
    );

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

    fixture.aliceDid = publishOfferResult.connectionOffer.groupOwnerDid!;
    fixture.bobDid = bobAcceptance.connectionOffer.permanentChannelDid!;
    fixture.charlieDid = charlieAcceptance.connectionOffer.permanentChannelDid!;
    fixture.groupDid = publishOfferResult.connectionOffer.groupDid!;

    return fixture;
  }
}
