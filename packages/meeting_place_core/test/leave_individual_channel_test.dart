import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/v_card.dart';
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;

  late Channel aliceChannel;
  late Channel bobChannel;

  bool assertMediatorClientException(Object? e) {
    if (e is MeetingPlaceCoreSDKException) {
      final coreSDKInnerException = e.innerException;
      return coreSDKInnerException is MediatorClientException;
    }
    return false;
  }

  setUpAll(() async {
    aliceSDK = await initSDKInstance();
    bobSDK = await initSDKInstance();

    final offer = await aliceSDK.publishOffer(
      offerName: 'Sample Offer 123',
      offerDescription: 'Sample offer description',
      maximumUsage: 1,
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

    final aliceCompleter = Completer<Channel>();
    final bobCompleter = Completer<Channel>();

    aliceSDK.controlPlaneEventsStream.listen((event) async {
      if (event.type == ControlPlaneEventType.InvitationAccept) {
        final channel =
            await aliceSDK.approveConnectionRequest(channel: event.channel);

        await bobSDK.processControlPlaneEvents();
        aliceCompleter.complete(channel);
      }
    });

    bobSDK.controlPlaneEventsStream.listen((event) async {
      if (event.type == ControlPlaneEventType.OfferFinalised) {
        bobCompleter.complete(event.channel);
      }
    });

    await aliceSDK.processControlPlaneEvents();

    aliceChannel = await aliceCompleter.future;
    bobChannel = await bobCompleter.future;
  });

  test('connection offer owner leaves channel', () async {
    await aliceSDK.leaveChannel(aliceChannel);

    final co = await aliceSDK.getConnectionOffer(aliceChannel.offerLink);
    final channel = await aliceSDK.getChannelByDid(
      aliceChannel.permanentChannelDid!,
    );

    // Connection offer status stays the same
    expect(co?.status, equals(ConnectionOfferStatus.published));

    // Channel entity has been deleted
    expect(channel, isNull);

    // Bob is not allowed to send messages to Alice anymore
    expect(
      () => bobSDK.sendMessage(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse('https://affinidi.io/test'),
          from: bobChannel.permanentChannelDid,
          to: [bobChannel.otherPartyPermanentChannelDid!],
        ),
        senderDid: bobChannel.permanentChannelDid!,
        recipientDid: bobChannel.otherPartyPermanentChannelDid!,
      ),
      throwsA(predicate(assertMediatorClientException)),
    );
  });

  test('other party leaves channel', () async {
    await bobSDK.leaveChannel(bobChannel);

    final co = await bobSDK.getConnectionOffer(bobChannel.offerLink);
    final channel = await bobSDK.getChannelByDid(
      bobChannel.permanentChannelDid!,
    );

    // Connection offer status stays the same
    expect(co?.status, equals(ConnectionOfferStatus.deleted));

    // Channel entity has been deleted
    expect(channel, isNull);

    // Alice is not allowed to send messages to Bob anymore
    expect(
      () => aliceSDK.sendMessage(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: Uri.parse('https://affinidi.io/test'),
          from: aliceChannel.permanentChannelDid,
          to: [aliceChannel.otherPartyPermanentChannelDid!],
        ),
        senderDid: aliceChannel.permanentChannelDid!,
        recipientDid: aliceChannel.otherPartyPermanentChannelDid!,
      ),
      throwsA(predicate(assertMediatorClientException)),
    );
  });
}
