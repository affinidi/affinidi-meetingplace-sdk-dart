import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
  });

  test(
    'connection offer contains vCard of publisher after publishing',
    () async {
      final expValues = {
        'n': {'given': 'Alice'},
      };

      final vCard = VCard(
        values: expValues,
      );

      final actual = await aliceSDK.publishOffer(
        offerName: 'Sample',
        vCard: vCard,
        type: SDKConnectionOfferType.invitation,
      );

      expect(
        actual.connectionOffer.vCard.values,
        equals(expValues),
      );
    },
  );
}
