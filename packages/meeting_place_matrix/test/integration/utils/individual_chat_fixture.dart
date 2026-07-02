import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';

import '../../utils/contact_card_fixture.dart' as fixtures;
import '../../utils/setup_chat_sdk.dart';

class IndividualChatFixture {
  IndividualChatFixture._({required this.setup});

  final SetupChatSdk setup;

  late SDKInstance aliceSDK;
  late SDKInstance bobSDK;

  late Channel aliceChannel;
  late Channel bobChannel;

  late MeetingPlaceMatrixChatSDK aliceChatSDK;
  late MeetingPlaceMatrixChatSDK bobChatSDK;

  static Future<IndividualChatFixture> create({
    SetupChatSdk? setup,
    ChannelTransport transport = ChannelTransport.didcomm,
  }) async {
    final fixture = IndividualChatFixture._(setup: setup ?? SetupChatSdk());

    fixture.aliceSDK = await fixture.setup.createCoreSDK(
      fixtures.ContactCardFixture.alicePrimaryCardInfo,
    );
    fixture.bobSDK = await fixture.setup.createCoreSDK(
      fixtures.ContactCardFixture.bobPrimaryCardInfo,
    );

    final (aliceChannel, bobChannel) = await fixture.setup
        .establishIndividualConnection(
          aliceSDK: fixture.aliceSDK,
          bobSDK: fixture.bobSDK,
          transport: transport,
        );
    fixture.aliceChannel = aliceChannel;
    fixture.bobChannel = bobChannel;

    fixture.aliceChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      channel: aliceChannel,
    );
    fixture.bobChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.bobSDK,
      channel: bobChannel,
    );

    // For Matrix transport, drain a sync cycle and force device-key fetches
    // on both clients so the first encrypted send creates an outbound megolm
    // session that both parties can decrypt. In production the natural latency
    // between connection setup and first send hides this race; tests collapse
    // it to milliseconds. Mirrors the same guard in GroupChatFixture.
    //
    // Use permanentChannelDid (not the identity DID) because that is what is
    // used to log into Matrix and is how _resolveRoomIdForDid looks up the
    // channel. otherPartyPermanentChannelDid is the peer's Matrix identity.
    if (transport == ChannelTransport.matrix) {
      await Future.wait([
        fixture.aliceSDK.coreSDK.waitForRoomEncryptionReady(
          localDid: aliceChannel.permanentChannelDid!,
          expectedDids: [aliceChannel.otherPartyPermanentChannelDid!],
        ),
        fixture.bobSDK.coreSDK.waitForRoomEncryptionReady(
          localDid: bobChannel.permanentChannelDid!,
          expectedDids: [bobChannel.otherPartyPermanentChannelDid!],
        ),
      ]);
    }

    return fixture;
  }

  Future<void> dispose() async {
    // Swallows a known didcomm 2.3.3 race where fetchMessagesOnConnect's
    // unawaited then-block calls _controller.add after stop() closed it.
    // Without this, tests fail "after completion" with StateError.
    await runZonedGuarded(
      () async {
        await aliceChatSDK.endChatSession();
        await bobChatSDK.endChatSession();
        await aliceSDK.coreSDK.dispose();
        await bobSDK.coreSDK.dispose();
      },
      (error, stackTrace) {
        if (error is StateError &&
            error.message.contains(
              'Cannot add new events after calling close',
            )) {
          return;
        }
        Zone.root.handleUncaughtError(error, stackTrace);
      },
    );
  }
}
