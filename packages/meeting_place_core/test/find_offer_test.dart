import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:test/test.dart';

import 'fixtures/contact_card_fixture.dart';
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
      offerDescription: 'Sample offer description',
      maximumUsage: 5,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: const {},
      ),
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

    expect(actual.connectionOffer!.contactCard.contactInfo, equals(const {}));

    expect(
      actual.connectionOffer!.maximumUsage,
      equals(connectionOffer.maximumUsage),
    );
  });

  test('returns offer group connection', () async {
    final result = await aliceSDK.publishOffer(
      offerName: 'Sample Offer',
      offerDescription: 'Sample offer description',
      type: SDKConnectionOfferType.groupInvitation,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: const {},
      ),
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
      offerDescription: 'Sample offer description',
      type: SDKConnectionOfferType.invitation,
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: const {},
      ),
    );

    expect(
      () => aliceSDK.findOffer(mnemonic: offer.connectionOffer.mnemonic),
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
  });

  test('find offer throws not found exception', () async {
    expect(
      () => aliceSDK.findOffer(mnemonic: 'does-not-exist'),
      throwsA(
        predicate((e) {
          return e is MeetingPlaceCoreSDKException &&
              (e.innerException as ConnectionOfferException).code ==
                  MeetingPlaceCoreSDKErrorCode.connectionOfferNotFoundError &&
              (e.innerException as ConnectionOfferException).message ==
                  'Offer not found.';
        }),
      ),
    );
  });
}
