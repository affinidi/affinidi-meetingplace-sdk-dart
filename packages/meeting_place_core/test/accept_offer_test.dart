import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:test/test.dart';
import 'fixtures/contact_card_fixture.dart';
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
    'connection offer contains ContactCard of accepter after accepting',
    () async {
      final aliceCard = ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      );

      final actual = (await aliceSDK.publishOffer(
        offerName: 'Sample',
        offerDescription: 'Sample offer description',
        contactCard: aliceCard,
        type: SDKConnectionOfferType.invitation,
      ));

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

  test('claim limit exceeded', () async {
    final aliceCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
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

    final bobCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    expect(
      () => charlieSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test:charlie',
          contactInfo: {
            'n': {'given': 'Charlie', 'surname': 'A.'},
          },
        ),
        senderInfo: 'Charlie',
      ),
      throwsA(isA<MeetingPlaceCoreSDKException>()),
    );
  });

  test('throws exception if user attempts to accept offer twice', () async {
    final aliceCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    );

    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      contactCard: aliceCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    final bobCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );
    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    expect(
      () => bobSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        contactCard: bobCard,
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
      final aliceCard = ContactCardFixture.getContactCardFixture(
        did: 'did:test:alice',
        contactInfo: {
          'n': {'given': 'Alice'},
        },
      );
      final publishedOfferResult = await aliceSDK.publishOffer(
        offerName: 'Test Offer',
        offerDescription: 'Sample offer description',
        contactCard: aliceCard,
        type: SDKConnectionOfferType.invitation,
      );

      expect(
        () => aliceSDK.acceptOffer(
          connectionOffer: publishedOfferResult.connectionOffer,
          contactCard: ContactCardFixture.getContactCardFixture(
            did: 'did:test:bob',
            contactInfo: {
              'n': {'given': 'Bob', 'surname': 'A.'},
            },
          ),
          senderInfo: 'Bob',
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
    final aliceCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:alice',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    );
    final publishedOfferResult = await aliceSDK.publishOffer(
      offerName: 'Test Offer',
      offerDescription: 'Sample offer description',
      contactCard: aliceCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: publishedOfferResult.connectionOffer.mnemonic,
    );

    final bobCard = ContactCardFixture.getContactCardFixture(
      did: 'did:test:bob',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );
    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    expect(
      () => bobSDK.acceptOffer(
        connectionOffer: findOfferResult.connectionOffer!,
        contactCard: bobCard,
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

  test('duplicate acceptance results in one channel only', () async {
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
      contactCard: aliceCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    final acceptance = await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
      senderInfo: 'Bob',
    );

    // Manually send a duplicate acceptance message to simulate the case where
    // multiple acceptance messages are generated due to retries or other
    // reasons.
    final invitationAcceptanceMessage = InvitationAcceptance.create(
      from: acceptance.connectionOffer.acceptOfferDid!,
      to: [acceptance.connectionOffer.publishOfferDid],
      parentThreadId: offer.connectionOffer.offerLink,
      channelDid: acceptance.connectionOffer.permanentChannelDid!,
      contactCard: bobCard,
    );

    final recipientDidDocument = await bobSDK.didResolver.resolveDid(
      acceptance.connectionOffer.publishOfferDid,
    );

    await bobSDK.mediator.sendMessage(
      invitationAcceptanceMessage.toPlainTextMessage(),
      senderDidManager: acceptance.acceptOfferDid,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: acceptance.connectionOffer.mediatorDid,
      next: acceptance.connectionOffer.publishOfferDid,
    );

    final completer = Completer<Channel>();
    int receivedInvitationAcceptEvents = 0;

    aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationAccept) {
        receivedInvitationAcceptEvents++;
        completer.complete(event.channel);
      }
    });

    await aliceSDK.processControlPlaneEvents();
    expect(await completer.future, isA<Channel>());
    expect(receivedInvitationAcceptEvents, equals(1));
  });
}
