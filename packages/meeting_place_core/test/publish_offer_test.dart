import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
  });

  test(
    'connection offer contains ContactCard of publisher after publishing',
    () async {
      final expInfo = {
        'n': {'given': 'Alice'},
      };

      final offerName = 'Sample Offer';
      final offerDescription = 'Sample offer description';
      final type = SDKConnectionOfferType.invitation;

      final actual = await aliceSDK.publishOffer(
        offerName: offerName,
        offerDescription: offerDescription,
        contactCard: ContactCard(
          did: 'did:test:alice',
          type: 'human',
          contactInfo: expInfo,
        ),
        type: type,
      );

      expect(actual.connectionOffer.offerName, equals(offerName));
      expect(actual.connectionOffer.offerDescription, equals(offerDescription));
      expect(actual.connectionOffer.card.contactInfo, equals(expInfo));
      expect(actual.connectionOffer.type,
          equals(ConnectionOfferType.meetingPlaceInvitation));
    },
  );
}
