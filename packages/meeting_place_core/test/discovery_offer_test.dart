import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';

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

  test(
    'party who registered the offer should not be able to claim it',
    () async {
      final publishedOfferResult = await aliceSDK.publishOffer(
        offerName: 'Test Offer',
        vCard: VCardFixture.alicePrimaryVCard,
        type: SDKConnectionOfferType.invitation,
      );

      expect(
        () => aliceSDK.acceptOffer(
          connectionOffer: publishedOfferResult.connectionOffer,
          vCard: VCardFixture.bobPrimaryVCard,
        ),
        throwsA(
          predicate(
            (e) =>
                e is MeetingPlaceCoreSDKException &&
                (e.innerException as ConnectionOfferException).errorCode ==
                    ConnectionOfferExceptionCodes
                        .connectionOfferOwnedByClaimingParty.code &&
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
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: publishedOfferResult.connectionOffer.mnemonic,
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
        predicate(
          (e) =>
              e is MeetingPlaceCoreSDKException &&
              (e.innerException as ConnectionOfferException).errorCode ==
                  ConnectionOfferExceptionCodes
                      .connectionOfferAlreadyClaimedByClaimingParty.code &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer already claimed by claiming party.',
        ),
      ),
    );
  });
}
