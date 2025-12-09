import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

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

    final aliceCard = ContactCard(
      did: 'did:test:alice',
      type: 'human',
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

    final bobCard = ContactCard(
      did: 'did:test:bob',
      type: 'human',
      contactInfo: {
        'n': {'given': 'Bob', 'surname': 'A.'},
      },
    );
    await bobSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobCard,
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

  test('send message', () async {
    final messageId = Uuid().v4();

    await aliceSDK.sendMessage(
      PlainTextMessage(
          id: messageId,
          from: aliceApprovedChannel.permanentChannelDid!,
          to: [aliceApprovedChannel.otherPartyPermanentChannelDid!],
          type: Uri.parse('https://example.org/plain-text'),
          body: {'text': 'Hello, Bob!'}),
      senderDid: aliceApprovedChannel.permanentChannelDid!,
      recipientDid: aliceApprovedChannel.otherPartyPermanentChannelDid!,
    );

    await Future.delayed(const Duration(seconds: 4));
    final messages = await bobSDK.fetchMessages(
        did: bobOfferFinalisedChannel.permanentChannelDid!);

    final actual =
        messages.firstWhereOrNull((m) => m.plainTextMessage.id == messageId);

    expect(actual, isNotNull);
  });

  test('throws exception if notification fails', () async {
    final messageId = Uuid().v4();

    aliceApprovedChannel.otherPartyNotificationToken =
        'invalid_notification_token';
    await aliceSDK.updateChannel(aliceApprovedChannel);

    expect(
        () => aliceSDK.sendMessage(
            PlainTextMessage(
                id: messageId,
                from: aliceApprovedChannel.permanentChannelDid!,
                to: [aliceApprovedChannel.otherPartyPermanentChannelDid!],
                type: Uri.parse('https://example.org/plain-text'),
                body: {'text': 'Hello, Bob!'}),
            senderDid: aliceApprovedChannel.permanentChannelDid!,
            recipientDid: aliceApprovedChannel.otherPartyPermanentChannelDid!,
            notifyChannelType: 'notify-channel'),
        throwsA(isA<MeetingPlaceCoreSDKException>().having(
          (e) => e.code,
          'code',
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value,
        )));
  });
}
