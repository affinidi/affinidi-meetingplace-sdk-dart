import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/approve_connection_request_fixture.dart';

void main() {
  late ApproveConnectionRequestFixture fixture;

  setUpAll(() async {
    fixture = await ApproveConnectionRequestFixture.create();
  });

  group('verify updates for connection offer owning party (Alice)', () {
    late ConnectionOffer connectionOffer;

    setUp(() async {
      connectionOffer =
          await fixture.aliceSDK.getConnectionOffer(
            fixture.aliceApprovedChannel.offerLink,
          ) ??
          fail('Connection offer does not exist');
    });

    test('existing channel has been updated', () async {
      expect(
        fixture.aliceApprovedChannel,
        equals(fixture.aliceInvitationAcceptChannel),
      );
    });

    test('channel has been updated with permanent channel DIDs', () async {
      expect(
        fixture.aliceApprovedChannel.permanentChannelDid,
        equals(fixture.bobOfferFinalisedChannel.otherPartyPermanentChannelDid),
      );

      expect(
        fixture.aliceApprovedChannel.otherPartyPermanentChannelDid,
        equals(fixture.bobOfferFinalisedChannel.permanentChannelDid),
      );
    });

    test('channel has been updated with notification token', () async {
      expect(fixture.aliceApprovedChannel.notificationToken, isNotNull);
    });

    test('channel status has been updated to approved', () async {
      expect(
        fixture.aliceApprovedChannel.status,
        equals(ChannelStatus.approved),
      );
    });

    test(
      'connection offer has been updated with permanent channel DIDs',
      () async {
        expect(
          connectionOffer.permanentChannelDid,
          equals(fixture.aliceApprovedChannel.permanentChannelDid),
        );

        expect(
          connectionOffer.otherPartyPermanentChannelDid,
          equals(fixture.bobOfferFinalisedChannel.permanentChannelDid),
        );
      },
    );

    test('connection offer stays in status published', () async {
      expect(connectionOffer.status, equals(ConnectionOfferStatus.published));
    });
  });

  group('verify updates for connection offer accepting party (Bob)', () {
    late ConnectionOffer connectionOffer;

    setUp(() async {
      connectionOffer =
          await fixture.bobSDK.getConnectionOffer(
            fixture.bobOfferFinalisedChannel.offerLink,
          ) ??
          fail('Connection offer does not exist');
    });

    test('channel has been updated with notification tokens', () {
      expect(fixture.bobOfferFinalisedChannel.notificationToken, isNotNull);
      expect(
        fixture.bobOfferFinalisedChannel.otherPartyNotificationToken,
        isNotNull,
      );
    });

    test(
      'channel has been updated with other party permanent channel DIDs',
      () {
        expect(
          fixture.bobOfferFinalisedChannel.otherPartyPermanentChannelDid,
          equals(fixture.aliceApprovedChannel.permanentChannelDid),
        );
      },
    );

    test('channel outbound message id has been updated with message id', () {
      expect(fixture.bobOfferFinalisedChannel.outboundMessageId, isNotNull);
    });

    test('channel status has been updated to inaugurated', () {
      expect(
        fixture.bobOfferFinalisedChannel.status,
        equals(ChannelStatus.inaugurated),
      );
    });

    test('connection offer status has been updated to finalised', () {
      expect(connectionOffer.status, equals(ConnectionOfferStatus.finalised));
    });

    test(
      'connection offer outbound message id has been updated with message id',
      () {
        expect(
          connectionOffer.outboundMessageId,
          equals(fixture.bobOfferFinalisedChannel.outboundMessageId),
        );
      },
    );

    test(
      'connection offer has been updated with other party permanent channel did',
      () {
        expect(
          connectionOffer.otherPartyPermanentChannelDid,
          equals(fixture.aliceApprovedChannel.permanentChannelDid),
        );
      },
    );

    test('connection offer has been updated with notification tokens', () {
      expect(
        connectionOffer.notificationToken,
        equals(fixture.bobOfferFinalisedChannel.notificationToken),
      );

      expect(connectionOffer.otherPartyNotificationToken, isNotNull);
    });
  });

  group('when channel is already approved', () {
    test('returns the same channel without making any changes', () async {
      final channelBeforeCall = fixture.aliceApprovedChannel;
      expect(
        channelBeforeCall.isApproved,
        isTrue,
        reason: 'Channel should already be approved',
      );

      final result = await fixture.aliceSDK.approveConnectionRequest(
        channel: channelBeforeCall,
      );

      expect(result, equals(channelBeforeCall));
      expect(
        result.permanentChannelDid,
        equals(channelBeforeCall.permanentChannelDid),
      );
      expect(result.status, equals(ChannelStatus.approved));
    });
  });
}
