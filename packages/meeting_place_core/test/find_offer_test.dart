import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  late ConnectionOffer connectionOffer;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();

    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer',
      maximumUsage: 5,
      vCard: VCard(values: {}),
      type: SDKConnectionOfferType.invitation,
    );
    connectionOffer = offer.connectionOffer;
  });

  test('returns offer connection', () async {
    final actual = await bobSDK.findOffer(mnemonic: connectionOffer.mnemonic);
    expect(actual, isA<FindOfferResult>());
    expect(
      actual.connectionOffer!.offerLink,
      equals(connectionOffer.offerLink),
    );
    expect(
      actual.connectionOffer!.offerName,
      equals(connectionOffer.offerName),
    );

    expect(
      actual.connectionOffer!.vCard.toJson(),
      equals(VCard(values: {}).toJson()),
    );

    expect(
      actual.connectionOffer!.maximumUsage,
      equals(connectionOffer.maximumUsage),
    );
  });

  test('returns offer group connection', () async {
    final result = await aliceSDK.publishOffer(
      offerName: 'Sample Offer',
      type: SDKConnectionOfferType.groupInvitation,
      vCard: VCard(values: {}),
    );

    final actual = await bobSDK.findOffer(
      mnemonic: result.connectionOffer.mnemonic,
    );

    expect(actual, isA<FindOfferResult>());
    expect(actual.connectionOffer, isA<GroupConnectionOffer>());
    expect(
      actual.connectionOffer?.offerLink,
      equals(result.connectionOffer.offerLink),
    );
  });

  test('return offer with error code because is owner', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer',
      type: SDKConnectionOfferType.invitation,
      vCard: VCard(values: {}),
    );

    expect(
      () => aliceSDK.findOffer(mnemonic: offer.connectionOffer.mnemonic),
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
  });

  test('query limit exceeded', () {}, skip: 'API has default of 100 queries');
}
