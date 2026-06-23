@Tags(['integration'])
library;

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/oob_flow_fixture.dart';

void main() {
  Channel? aliceChannel;
  Channel? bobChannel;
  Channel? bobChannelBeforeApproval;
  ChannelStatus? bobStatusBeforeApproval;
  String? bobOtherPartyDidBeforeApproval;
  ContactCard? bobOtherPartyCardBeforeApproval;

  setUpAll(() async {
    final fixture = await OobFlowFixture.create();

    final oobOfferSession = await fixture.createOobFlow();
    final oobAcceptanceSession = await fixture.acceptOobFlow(
      oobOfferSession.oobUrl,
    );

    bobChannelBeforeApproval = oobAcceptanceSession.channel;
    bobStatusBeforeApproval = bobChannelBeforeApproval!.status;
    bobOtherPartyDidBeforeApproval =
        bobChannelBeforeApproval!.otherPartyPermanentChannelDid;
    bobOtherPartyCardBeforeApproval =
        bobChannelBeforeApproval!.otherPartyContactCard;

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

  group('successful channel creation for OOB flow', () {
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
    test('status is waiting for approval', () {
      expect(bobStatusBeforeApproval, ChannelStatus.waitingForApproval);
    });

    test('initial values are set', () {
      expect(bobChannelBeforeApproval?.offerLink, isNotNull);
      expect(bobChannelBeforeApproval?.publishOfferDid, isNotNull);
      expect(bobChannelBeforeApproval?.mediatorDid, isNotNull);
      expect(bobChannelBeforeApproval?.outboundMessageId, isNotNull);
      expect(bobChannelBeforeApproval?.acceptOfferDid, isNotNull);
      expect(bobChannelBeforeApproval?.permanentChannelDid, isNotNull);
      expect(bobChannelBeforeApproval?.type, equals(ChannelType.oob));
      expect(bobOtherPartyDidBeforeApproval, isNull);
      expect(bobOtherPartyCardBeforeApproval, isNull);

      expect(
        bobChannelBeforeApproval?.contactCard?.contactInfo,
        equals({
          'n': {'given': 'Bob', 'surname': 'A.'},
        }),
      );
    });
  });

  group('channel state after alice approves', () {
    test('status is inaugurated', () {
      expect(bobChannel?.status, ChannelStatus.inaugurated);
    });

    test('initial values are still the same', () {
      expect(bobChannel?.offerLink, bobChannelBeforeApproval?.offerLink);
      expect(
        bobChannel?.publishOfferDid,
        bobChannelBeforeApproval?.publishOfferDid,
      );
      expect(bobChannel?.mediatorDid, bobChannelBeforeApproval?.mediatorDid);
      expect(
        bobChannel?.outboundMessageId,
        bobChannelBeforeApproval?.outboundMessageId,
      );
      expect(
        bobChannel?.acceptOfferDid,
        bobChannelBeforeApproval?.acceptOfferDid,
      );
      expect(
        bobChannel?.permanentChannelDid,
        bobChannelBeforeApproval!.permanentChannelDid,
      );
      expect(bobChannel?.type, bobChannelBeforeApproval!.type);
      expect(
        bobChannel?.contactCard?.contactInfo,
        equals(bobChannelBeforeApproval?.contactCard?.contactInfo),
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
