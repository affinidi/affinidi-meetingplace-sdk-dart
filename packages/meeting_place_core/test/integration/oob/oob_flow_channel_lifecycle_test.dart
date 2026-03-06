import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/oob_flow_fixture.dart';

void main() {
  group('successful channel creation for OOB flow', () {
    Channel? aliceChannel;
    Channel? bobChannel;

    setUpAll(() async {
      final fixture = await OobFlowFixture.create();

      final oobOfferSession = await fixture.createOobFlow();
      final oobAcceptanceSession = await fixture.acceptOobFlow(
        oobOfferSession.oobUrl,
      );

      final aliceFuture = OobFlowFixture.waitForFirstChannelFromCreate(
        oobOfferSession,
      );
      final bobFuture = OobFlowFixture.waitForFirstChannelFromAccept(
        oobAcceptanceSession,
      );

      final channels = await Future.wait([aliceFuture, bobFuture]);
      aliceChannel = channels[0];
      bobChannel = channels[1];
    });

    test('permanent dids match', () {
      expect(
        aliceChannel?.permanentChannelDid,
        bobChannel?.otherPartyPermanentChannelDid,
      );

      expect(
        aliceChannel?.otherPartyPermanentChannelDid,
        bobChannel?.permanentChannelDid,
      );
    });

    test('Contact cards match', () {
      expect(
        aliceChannel?.contactCard?.contactInfo,
        bobChannel?.otherPartyContactCard?.contactInfo,
      );

      expect(
        aliceChannel?.otherPartyContactCard?.contactInfo,
        bobChannel?.contactCard?.contactInfo,
      );
    });

    test('channel status is inaugurated', () {
      expect(aliceChannel?.status, equals(ChannelStatus.inaugurated));
      expect(bobChannel?.status, equals(ChannelStatus.inaugurated));
    });

    test('mediator dids match', () {
      expect(aliceChannel?.mediatorDid, equals(bobChannel?.mediatorDid));
    });

    test('other dids / ids match', () {
      expect(aliceChannel?.offerLink, bobChannel?.offerLink);

      expect(
        aliceChannel?.publishOfferDid,
        equals(bobChannel?.publishOfferDid),
      );

      expect(aliceChannel?.acceptOfferDid, equals(bobChannel?.acceptOfferDid));

      expect(
        aliceChannel?.outboundMessageId,
        equals(bobChannel?.outboundMessageId),
      );
    });

    test('type is oob', () {
      expect(aliceChannel?.type, ChannelType.oob);
    });
  });

  group('channel state before alice approves', () {
    Channel? bobChannel;

    setUpAll(() async {
      final fixture = await OobFlowFixture.create();
      final createOobFlowResult = await fixture.createOobFlow();
      final acceptOobFlowResult = await fixture.acceptOobFlow(
        createOobFlowResult.oobUrl,
      );

      bobChannel = acceptOobFlowResult.channel;
    });

    test('status is waiting for approval', () {
      expect(bobChannel?.status, ChannelStatus.waitingForApproval);
    });

    test('initial values are set', () {
      expect(bobChannel?.offerLink, isNotNull);
      expect(bobChannel?.publishOfferDid, isNotNull);
      expect(bobChannel?.mediatorDid, isNotNull);
      expect(bobChannel?.outboundMessageId, isNotNull);
      expect(bobChannel?.acceptOfferDid, isNotNull);
      expect(bobChannel?.permanentChannelDid, isNotNull);
      expect(bobChannel?.type, equals(ChannelType.oob));
      expect(bobChannel?.otherPartyPermanentChannelDid, isNull);
      expect(bobChannel?.otherPartyContactCard, isNull);

      expect(
        bobChannel?.contactCard?.contactInfo,
        equals({
          'n': {'given': 'Bob', 'surname': 'A.'},
        }),
      );
    });
  });

  group('channel state after alice approves', () {
    Channel? bobChannel;
    Channel? channelBefore;

    setUpAll(() async {
      final fixture = await OobFlowFixture.create();
      final createOobFlowResult = await fixture.createOobFlow();
      final acceptOobFlowResult = await fixture.acceptOobFlow(
        createOobFlowResult.oobUrl,
      );

      channelBefore = acceptOobFlowResult.channel;
      bobChannel = await OobFlowFixture.waitForFirstChannelFromAccept(
        acceptOobFlowResult,
      );
    });

    test('status is inaugurated', () {
      expect(bobChannel?.status, ChannelStatus.inaugurated);
    });

    test('initial values are still the same', () {
      expect(bobChannel?.offerLink, channelBefore?.offerLink);
      expect(bobChannel?.publishOfferDid, channelBefore?.publishOfferDid);
      expect(bobChannel?.mediatorDid, channelBefore?.mediatorDid);
      expect(bobChannel?.outboundMessageId, channelBefore?.outboundMessageId);
      expect(bobChannel?.acceptOfferDid, channelBefore?.acceptOfferDid);
      expect(
        bobChannel?.permanentChannelDid,
        channelBefore!.permanentChannelDid,
      );
      expect(bobChannel?.type, channelBefore!.type);
      expect(
        bobChannel?.contactCard?.contactInfo,
        equals(channelBefore?.contactCard?.contactInfo),
      );
    });

    test('channel has been updated', () {
      expect(bobChannel?.otherPartyPermanentChannelDid, isNotNull);
      expect(bobChannel?.otherPartyContactCard?.contactInfo, {
        'n': {'given': 'Alice'},
      });
    });
  });
}
