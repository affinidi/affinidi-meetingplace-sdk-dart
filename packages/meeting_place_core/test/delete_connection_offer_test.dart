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

  test('connection offer is marked as deleted', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(Duration(seconds: 60)),
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final updatedConnectionOffer = await aliceSDK.markConnectionOfferAsDeleted(
      offer.connectionOffer,
    );

    expect(updatedConnectionOffer.status, ConnectionOfferStatus.deleted);
    expect(updatedConnectionOffer.isDeleted, isTrue);

    final connectionOfferFromStorage = await aliceSDK.getConnectionOffer(
      offer.connectionOffer.offerLink,
    );

    expect(connectionOfferFromStorage!.status, ConnectionOfferStatus.deleted);
    expect(connectionOfferFromStorage.isDeleted, isTrue);
  });

  test('gracefully handles multiple deletion calls', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(Duration(seconds: 60)),
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final deletedConnectionOffer = await aliceSDK.markConnectionOfferAsDeleted(
      offer.connectionOffer,
    );
    await aliceSDK.markConnectionOfferAsDeleted(deletedConnectionOffer);

    final connectionOfferFromStorage = await aliceSDK.getConnectionOffer(
      offer.connectionOffer.offerLink,
    );

    expect(connectionOfferFromStorage!.status, ConnectionOfferStatus.deleted);
    expect(connectionOfferFromStorage.isDeleted, isTrue);
  });

  test('delete connection offer from storage', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(Duration(seconds: 60)),
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    await aliceSDK.deleteConnectionOffer(offer.connectionOffer);
    final actual = await aliceSDK.getConnectionOffer(
      offer.connectionOffer.offerLink,
    );

    expect(actual, isNull);
  });

  test('deregister offer from control plane', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(Duration(seconds: 60)),
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    await aliceSDK.deleteConnectionOffer(offer.connectionOffer);

    expect(
      () => aliceSDK.findOffer(mnemonic: offer.connectionOffer.mnemonic),
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

  test('skips deregister offer from MPX discovery if not the owner', () async {
    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(Duration(seconds: 60)),
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    final acceptOfferResult = await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    await aliceSDK.deleteConnectionOffer(acceptOfferResult.connectionOffer);

    final actual = await aliceSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    expect(actual.connectionOffer, isNotNull);
  });
}
