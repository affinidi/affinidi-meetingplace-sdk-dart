import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  late Channel aliceInvitationAcceptChannel;
  late Channel aliceApprovedChannel;
  late Channel bobOfferFinalisedChannel;

  setUpAll(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();

    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      vCard: VCardFixture.alicePrimaryVCard,
      type: SDKConnectionOfferType.invitation,
    );

    final findOfferResult = await bobSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );

    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      vCard: VCardFixture.bobPrimaryVCard,
      senderInfo: 'Bob',
    );

    final waitForInvitationAccept = Completer<Channel>();
    aliceSDK.controlPlaneEventsStream
        .where((event) =>
            event.matchesType(ControlPlaneEventType.InvitationAccept))
        .listen((event) => waitForInvitationAccept.complete(event.channel));

    final waitForOfferFinalised = Completer<Channel>();
    bobSDK.controlPlaneEventsStream
        .where(
            (event) => event.matchesType(ControlPlaneEventType.OfferFinalised))
        .listen((event) => waitForOfferFinalised.complete(event.channel));

    await aliceSDK.processControlPlaneEvents();
    aliceInvitationAcceptChannel = await waitForInvitationAccept.future;

    aliceApprovedChannel = await aliceSDK.approveConnectionRequest(
      channel: aliceInvitationAcceptChannel,
    );

    await bobSDK.processControlPlaneEvents();
    bobOfferFinalisedChannel = await waitForOfferFinalised.future;
  });

  group('verify updates for connection offer owning party (Alice)', () {
    late ConnectionOffer connectionOffer;

    setUp(() async {
      connectionOffer = await aliceSDK.getConnectionOffer(
            aliceApprovedChannel.offerLink,
          ) ??
          fail('Connection offer does not exist');
    });

    test('existing channel has been updated', () async {
      expect(aliceApprovedChannel, equals(aliceInvitationAcceptChannel));
    });

    test('channel has been updated with permanent channel DIDs', () async {
      expect(aliceApprovedChannel.permanentChannelDid,
          equals(bobOfferFinalisedChannel.otherPartyPermanentChannelDid));

      expect(aliceApprovedChannel.otherPartyPermanentChannelDid,
          equals(bobOfferFinalisedChannel.permanentChannelDid));
    });

    test('channel has been updated with notification token', () async {
      expect(aliceApprovedChannel.notificationToken, isNotNull);
    });

    test('channel status has been updated to approved', () async {
      expect(aliceApprovedChannel.status, equals(ChannelStatus.approved));
    });

    test('connection offer has been updated with permanent channel DIDs',
        () async {
      expect(connectionOffer.permanentChannelDid,
          equals(aliceApprovedChannel.permanentChannelDid));

      expect(connectionOffer.otherPartyPermanentChannelDid,
          equals(bobOfferFinalisedChannel.permanentChannelDid));
    });

    test('connection offer stays in status published', () async {
      expect(connectionOffer.status, equals(ConnectionOfferStatus.published));
    });
  });

  group('verify updates for connection offer accepting party (Bob)', () {
    late ConnectionOffer connectionOffer;

    setUp(() async {
      connectionOffer = await bobSDK.getConnectionOffer(
            bobOfferFinalisedChannel.offerLink,
          ) ??
          fail('Connection offer does not exist');
    });

    test('channel has been updated with notification tokens', () {
      expect(bobOfferFinalisedChannel.notificationToken, isNotNull);
      expect(bobOfferFinalisedChannel.otherPartyNotificationToken, isNotNull);
    });

    test('channel has been updated with other party permanent channel DIDs',
        () {
      expect(bobOfferFinalisedChannel.otherPartyPermanentChannelDid,
          equals(aliceApprovedChannel.permanentChannelDid));
    });

    test('channel outbound message id has been updated with message id', () {
      expect(bobOfferFinalisedChannel.outboundMessageId, isNotNull);
    });

    test('channel status has been updated to inaugurated', () {
      expect(
          bobOfferFinalisedChannel.status, equals(ChannelStatus.inaugurated));
    });

    test('connection offer status has been updated to finalised', () {
      expect(connectionOffer.status, equals(ConnectionOfferStatus.finalised));
    });

    test(
        'connection offer outbound message id has been updated with message id',
        () {
      expect(connectionOffer.outboundMessageId,
          equals(bobOfferFinalisedChannel.outboundMessageId));
    });

    test(
        'connection offer has been updated with other party permanent channel did',
        () {
      expect(connectionOffer.otherPartyPermanentChannelDid,
          equals(aliceApprovedChannel.permanentChannelDid));
    });

    test('connection offer has been updated with notification tokens', () {
      expect(connectionOffer.notificationToken,
          equals(bobOfferFinalisedChannel.notificationToken));

      expect(connectionOffer.otherPartyNotificationToken, isNotNull);
    });
  });
}
