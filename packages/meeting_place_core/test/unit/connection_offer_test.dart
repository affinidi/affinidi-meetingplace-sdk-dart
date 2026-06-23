import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

void main() {
  final contactCard = ContactCardFixture.getContactCardFixture(
    did: 'did:test:contact',
    contactInfo: const {'fullName': 'Test User'},
  );

  final baseOffer = ConnectionOffer(
    offerName: 'Test Offer',
    offerLink: 'https://example.com/offer',
    type: ConnectionOfferType.meetingPlaceInvitation,
    mnemonic: 'test-mnemonic',
    publishOfferDid: 'did:example:publish',
    mediatorDid: 'did:example:mediator',
    oobInvitationMessage: '',
    contactCard: contactCard,
    status: ConnectionOfferStatus.published,
    ownedByMe: true,
    createdAt: DateTime.utc(2024),
    transport: ChannelTransport.didcomm,
  );

  group('ConnectionOffer score', () {
    group('copyWith', () {
      test('sets score when provided', () {
        final result = baseOffer.copyWith(score: 7);
        expect(result.score, equals(7));
      });

      test('preserves existing score when not specified', () {
        final offerWithScore = baseOffer.copyWith(score: 5);
        final result = offerWithScore.copyWith(externalRef: 'some-ref');
        expect(result.score, equals(5));
      });

      test('preserves existing score when null is explicitly passed', () {
        // score ?? this.score means passing null keeps the existing value
        final offerWithScore = baseOffer.copyWith(score: 5);
        final result = offerWithScore.copyWith(score: null);
        expect(result.score, equals(5));
      });

      test('score is null by default', () {
        expect(baseOffer.score, isNull);
      });
    });

    group('accept()', () {
      test('preserves existing score when score not specified', () {
        final offerWithScore = baseOffer.copyWith(score: 5);

        final accepted = offerWithScore.accept(
          acceptOfferDid: 'did:example:accept',
          permanentChannelDid: 'did:example:permanent',
          card: contactCard,
          createdAt: DateTime.utc(2024),
        );

        expect(accepted.score, equals(5));
      });

      test('uses provided score, overriding existing', () {
        final offerWithScore = baseOffer.copyWith(score: 3);

        final accepted = offerWithScore.accept(
          acceptOfferDid: 'did:example:accept',
          permanentChannelDid: 'did:example:permanent',
          card: contactCard,
          createdAt: DateTime.utc(2024),
          score: 10,
        );

        expect(accepted.score, equals(10));
      });

      test('score remains null if offer has no score and none is provided', () {
        final accepted = baseOffer.accept(
          acceptOfferDid: 'did:example:accept',
          permanentChannelDid: 'did:example:permanent',
          card: contactCard,
          createdAt: DateTime.utc(2024),
        );

        expect(accepted.score, isNull);
      });

      test('sets score from null when explicitly provided', () {
        final accepted = baseOffer.accept(
          acceptOfferDid: 'did:example:accept',
          permanentChannelDid: 'did:example:permanent',
          card: contactCard,
          createdAt: DateTime.utc(2024),
          score: 4,
        );

        expect(accepted.score, equals(4));
      });

      test('sets status to accepted', () {
        final offerWithScore = baseOffer.copyWith(score: 5);

        final accepted = offerWithScore.accept(
          acceptOfferDid: 'did:example:accept',
          permanentChannelDid: 'did:example:permanent',
          card: contactCard,
          createdAt: DateTime.utc(2024),
        );

        expect(accepted.status, equals(ConnectionOfferStatus.accepted));
      });
    });
  });
}
