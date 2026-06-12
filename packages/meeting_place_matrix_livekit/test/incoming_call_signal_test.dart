import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show IncomingCallEvent;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix_livekit/meeting_place_matrix_livekit.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mocks.dart';

MeetingPlaceLiveKitCallPlugin _plugin() => MeetingPlaceLiveKitCallPlugin(
  options: MeetingPlaceLiveKitCallPluginOptions(
    livekitServiceUrl: Uri.parse('https://livekit.example.com'),
  ),
);

Channel _channel({required String ownDid, required String? otherPartyDid}) =>
    Channel(
      offerLink: 'offer-link',
      publishOfferDid: 'did:key:publishOffer',
      mediatorDid: 'did:key:mediator',
      status: ChannelStatus.inaugurated,
      contactCard: ContactCard(
        did: 'did:key:contact',
        type: 'individual',
        contactInfo: const {},
      ),
      type: ChannelType.individual,
      isConnectionInitiator: false,
      permanentChannelDid: ownDid,
      otherPartyPermanentChannelDid: otherPartyDid,
    );

void main() {
  const callerDid = 'did:key:callerChannelDid';
  const ownDid = 'did:key:ownChannelDid';

  late MockMeetingPlaceCoreSDK mockSdk;
  late StreamController<IncomingCallSignal> signalController;
  late MeetingPlaceLiveKitCallPlugin plugin;

  setUpAll(() {
    registerFallbackValue(MockDidManager());
    registerFallbackValue(_channel(ownDid: ownDid, otherPartyDid: callerDid));
    registerFallbackValue(MockWebRTCDelegate());
  });

  setUp(() {
    mockSdk = MockMeetingPlaceCoreSDK();
    signalController = StreamController<IncomingCallSignal>.broadcast();

    when(
      () => mockSdk.incomingCallSignals,
    ).thenAnswer((_) => signalController.stream);

    plugin = _plugin();
    plugin.initialize(sdk: mockSdk);
  });

  tearDown(() async {
    plugin.disposeCall();
    await plugin.dispose();
    await signalController.close();
  });

  group('_onIncomingCallSignal', () {
    test('happy path: rings immediately with caller channel DID', () async {
      when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer(
        (_) async => _channel(ownDid: ownDid, otherPartyDid: callerDid),
      );

      final eventFuture = plugin.incomingCalls.first;
      signalController.add(const IncomingCallSignal(ownChannelDid: ownDid));

      final event = await eventFuture.timeout(const Duration(seconds: 5));
      expect(event.callId, callerDid);
      expect(event.contactId, callerDid);
      expect(event.isAudioOnly, isFalse);
    });

    test(
      'drops signal when channel has no otherPartyPermanentChannelDid',
      () async {
        when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => _channel(ownDid: ownDid, otherPartyDid: null),
        );

        final emitted = <IncomingCallEvent>[];
        final sub = plugin.incomingCalls.listen(emitted.add);

        signalController.add(const IncomingCallSignal(ownChannelDid: ownDid));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emitted, isEmpty);
        await sub.cancel();
      },
    );

    test('drops signal when no channel is found for own DID', () async {
      when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer((_) async => null);

      final emitted = <IncomingCallEvent>[];
      final sub = plugin.incomingCalls.listen(emitted.add);

      signalController.add(const IncomingCallSignal(ownChannelDid: ownDid));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, isEmpty);
      await sub.cancel();
    });
  });
}
