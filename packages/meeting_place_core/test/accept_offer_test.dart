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
      offerDescription: 'Sample offer description',
      maximumUsage: 1,
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
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

  test('connection offer contains vCard of accepter after accepting', () async {
    final actual = (await aliceSDK.publishOffer(
      offerName: 'Sample',
      offerDescription: 'Sample offer description',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    ));

    final acceptOfferResult = await bobSDK.acceptOffer(
      connectionOffer: actual.connectionOffer,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    expect(
      acceptOfferResult.connectionOffer.vCard.values,
      equals(VCardFixture.bobPrimaryVCard.values),
    );
  });

  test('claim limit exceeded', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      maximumUsage: 1,
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    expect(
      () => charlieSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        vCard: VCardFixture.charliePrimaryVCard,
        senderInfo: 'Charlie',
      ),
      throwsA(isA<MeetingPlaceCoreSDKException>()),
    );
  });

  test('throws exception if user attempts to accept offer twice', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    expect(
      () => bobSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        vCard: VCardFixture.bobPrimaryVCard,
        senderInfo: 'Bob',
      ),
      throwsA(
        predicate((e) {
          return e is MeetingPlaceCoreSDKException &&
              e.innerException is ConnectionOfferException &&
              (e.innerException as ConnectionOfferException).code ==
                  MeetingPlaceCoreSDKErrorCode
                      .connectionOfferAlreadyClaimedByClaimingParty &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer already claimed by claiming party.';
        }),
      ),
    );
  });

  test(
    'party who registered the offer should not be able to claim it',
    () async {
      final publishedOfferResult = await aliceSDK.publishOffer(
        offerName: 'Test Offer',
        offerDescription: 'Sample offer description',
        vCard: VCardFixture.alicePrimaryVCard,
        type: SDKConnectionOfferType.invitation,
      );

      expect(
        () => aliceSDK.acceptOffer(
          connectionOffer: publishedOfferResult.connectionOffer,
          vCard: VCardFixture.bobPrimaryVCard,
          senderInfo: 'Alice',
        ),
        throwsA(
          predicate(
            (e) =>
                e is MeetingPlaceCoreSDKException &&
                (e.innerException as ConnectionOfferException).code ==
                    MeetingPlaceCoreSDKErrorCode
                        .connectionOfferOwnedByClaimingParty &&
                (e.innerException as ConnectionOfferException).message ==
                    'Failed to claim offer because claiming party is the owner.',
          ),
        ),
      );
    },
  );

  test('throws error if offer claiming is in progress', () async {
    final publishedOfferResult = await aliceSDK.publishOffer(
      offerName: 'Test Offer',
      offerDescription: 'Sample offer description',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: publishedOfferResult.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    expect(
      () => bobSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        vCard: VCardFixture.bobPrimaryVCard,
        senderInfo: 'Bob',
      ),
      throwsA(
        predicate(
          (e) =>
              e is MeetingPlaceCoreSDKException &&
              (e.innerException as ConnectionOfferException).code ==
                  MeetingPlaceCoreSDKErrorCode
                      .connectionOfferAlreadyClaimedByClaimingParty &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer already claimed by claiming party.',
        ),
      ),
    );
  });
}
