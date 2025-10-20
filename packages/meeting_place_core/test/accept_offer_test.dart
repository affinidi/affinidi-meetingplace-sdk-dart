import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:test/test.dart';
import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;
  late MeetingPlaceCoreSDK charlieSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
    charlieSDK = await initSDKInstance();
  });

  test('accept offer uses correct vcard', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      maximumUsage: 1,
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
    });

    await aliceSDK.processControlPlaneEvents();
    await completer.future;

    expect(
      channel.vCard?.values,
      equals(VCardFixture.alicePrimaryVCard.values),
    );

    expect(
      channel.otherPartyVCard?.values,
      equals(VCardFixture.bobPrimaryVCard.values),
    );
  });

  test('claim limit exceeded', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      maximumUsage: 1,
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

    expect(
      () => charlieSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        vCard: VCardFixture.charliePrimaryVCard,
      ),
      throwsA(isA<MeetingPlaceCoreSDKException>()),
    );
  });

  test('throws exception if user attempts to accept offer twice', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
    );

    expect(
      () => bobSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        vCard: VCardFixture.bobPrimaryVCard,
      ),
      throwsA(
        predicate((e) {
          return e is MeetingPlaceCoreSDKException &&
              e.innerException is ConnectionOfferException &&
              (e.innerException as ConnectionOfferException).errorCode ==
                  ConnectionOfferExceptionCodes
                      .connectionOfferAlreadyClaimedByClaimingParty.code &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer already claimed by claiming party.';
        }),
      ),
    );
  });
}
