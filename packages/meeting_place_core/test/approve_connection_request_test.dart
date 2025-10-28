import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('handle finalised offer event', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    final acceptResult = await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    await bobSDK.notifyAcceptance(
      connectionOffer: acceptResult.connectionOffer,
      senderInfo: 'Bob',
    );

    final completer = Completer<void>();
    late Channel channel;
    aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationAccept) {
        channel = event.channel;
        completer.complete();
      }
    }).onError((err) => fail(err.toString()));

    await aliceSDK.processControlPlaneEvents();
    await completer.future;

    final connectionOffer = await aliceSDK.getConnectionOffer(
      findOfferResult.connectionOffer!.offerLink,
    );

    await aliceSDK.approveConnectionRequest(
      connectionOffer: connectionOffer!,
      channel: channel,
    );

    // final waitForBobOfferFinalised = DiscoveryTestUtils.waitForDiscoveryEvent(
    //   bobSDK,
    //   eventType: DiscoveryEventType.OfferFinalised,
    //   expectedNumberOfEvents: 1,
    // );
    // await bobSDK.processControlPlaneEvents();
    // await waitForBobOfferFinalised.future;

    // final actual =
    //     await bobSDK.getConnectionOffer(acceptResult.connectionOffer.offerLink);

    // expect(actual!.status, equals(ConnectionOfferStatus.finalised));
  });
}
