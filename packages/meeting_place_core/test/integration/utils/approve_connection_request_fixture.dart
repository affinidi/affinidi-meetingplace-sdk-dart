import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

class ApproveConnectionRequestFixture {
  ApproveConnectionRequestFixture._();

  late final MeetingPlaceCoreSDK aliceSDK;
  late final MeetingPlaceCoreSDK bobSDK;

  late final Channel aliceInvitationAcceptChannel;
  late final Channel aliceApprovedChannel;
  late final Channel bobOfferFinalisedChannel;

  static Future<ApproveConnectionRequestFixture> create() async {
    final fixture = ApproveConnectionRequestFixture._();

    fixture.aliceSDK = await initSDKInstance();
    fixture.bobSDK = await initSDKInstance();

    final offer = await fixture.aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await fixture.bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await fixture.bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: {
          'n': {'given': 'Bob', 'surname': 'A.'},
        },
      ),
      senderInfo: 'Bob',
    );

    final waitForInvitationAccept = Completer<Channel>();
    fixture.aliceSDK.controlPlaneEventsStream
        .where(
          (event) => event.matchesType(ControlPlaneEventType.InvitationAccept),
        )
        .listen((event) {
          if (!waitForInvitationAccept.isCompleted) {
            waitForInvitationAccept.complete(event.channel);
          }
        });

    final waitForOfferFinalised = Completer<Channel>();
    fixture.bobSDK.controlPlaneEventsStream
        .where(
          (event) => event.matchesType(ControlPlaneEventType.OfferFinalised),
        )
        .listen((event) {
          if (!waitForOfferFinalised.isCompleted) {
            waitForOfferFinalised.complete(event.channel);
          }
        });

    await fixture.aliceSDK.processControlPlaneEvents();
    fixture.aliceInvitationAcceptChannel = await waitForInvitationAccept.future;

    fixture.aliceApprovedChannel = await fixture.aliceSDK
        .approveConnectionRequest(
          channel: fixture.aliceInvitationAcceptChannel,
        );

    await fixture.bobSDK.processControlPlaneEvents();
    fixture.bobOfferFinalisedChannel = await waitForOfferFinalised.future;

    return fixture;
  }
}
