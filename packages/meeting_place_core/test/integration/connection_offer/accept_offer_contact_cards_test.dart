import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../../fixtures/contact_card_fixture.dart';
import '../../utils/sdk.dart';

void main() {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();
  });

  test('accept offer uses correct contact card', () async {
    final aliceCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    );

    final bobCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );

    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      maximumUsage: 1,
      contactCard: aliceCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
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

    expect(channel.contactCard?.contactInfo, equals(aliceCard.contactInfo));

    expect(
      channel.otherPartyContactCard?.contactInfo,
      equals(bobCard.contactInfo),
    );
  });

  test(
    'connection offer contains ContactCard of the accepter after acceptance',
    () async {
      final aliceCard = ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      );

      final actual = await aliceSDK.publishOffer(
        offerName: 'Sample',
        offerDescription: 'Sample offer description',
        contactCard: aliceCard,
        type: SDKConnectionOfferType.invitation,
      );

      final bobCard = ContactCardFixture.getContactCardFixture(
        did: 'did:test:bob',
        contactInfo: {
          'n': {'given': 'Bob', 'surname': 'A.'},
        },
      );
      final acceptOfferResult = await bobSDK.acceptOffer(
        connectionOffer: actual.connectionOffer,
        contactCard: bobCard,
        senderInfo: 'Bob',
      );

      expect(
        acceptOfferResult.connectionOffer.contactCard.contactInfo,
        equals(bobCard.contactInfo),
      );
    },
  );
}
