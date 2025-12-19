import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'fixtures/contact_card_fixture.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK sdk;

  setUpAll(() async {
    sdk = await initSDKInstance(withoutDevice: true);
  });

  test('register for DIDComm notifications returns new DIDManager', () async {
    final result = await sdk.registerForDIDCommNotifications(
      mediatorDid: getMediatorDid(),
    );

    // Run action to authenticate & register device
    await sdk.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      validUntil: DateTime.now().toUtc().add(const Duration(seconds: 30)),
      contactCard: ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      ),
      type: SDKConnectionOfferType.invitation,
    );

    expect(sdk.discovery.device.deviceToken, result.device.deviceToken);
    expect(sdk.discovery.device.platformType, PlatformType.didcomm);
    expect(result.recipientDid, isA<DidManager>());

    // TODO: test notifications
  });

  test('register for DIDComm notifications reuses given DID', () async {
    final recipientDid = await sdk.generateDid();
    final recipientDidDoc = await recipientDid.getDidDocument();

    final result = await sdk.registerForDIDCommNotifications(
      mediatorDid: 'did:web:other-mediator',
      recipientDid: recipientDidDoc.id,
    );

    final actual = await result.recipientDid.getDidDocument();
    expect(recipientDidDoc.id, equals(actual.id));
  });
}
