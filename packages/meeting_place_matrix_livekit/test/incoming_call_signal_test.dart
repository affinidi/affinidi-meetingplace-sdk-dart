import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show IncomingAudioVideoCallEvent;
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

    when(
      () => mockSdk.callDeclineSignals,
    ).thenAnswer((_) => const Stream.empty());

    plugin = _plugin();
    plugin.initialize(sdk: mockSdk);
  });

  tearDown(() async {
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
      expect(event.otherPartyChannelDid, callerDid);
      expect(event.mediaType, CallMediaType.video);
    });

    test(
      'drops signal when channel has no otherPartyPermanentChannelDid',
      () async {
        when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer(
          (_) async => _channel(ownDid: ownDid, otherPartyDid: null),
        );

        final emitted = <IncomingAudioVideoCallEvent>[];
        final sub = plugin.incomingCalls.listen(emitted.add);

        signalController.add(const IncomingCallSignal(ownChannelDid: ownDid));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emitted, isEmpty);
        await sub.cancel();
      },
    );

    test('drops signal when no channel is found for own DID', () async {
      when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer((_) async => null);

      final emitted = <IncomingAudioVideoCallEvent>[];
      final sub = plugin.incomingCalls.listen(emitted.add);

      signalController.add(const IncomingCallSignal(ownChannelDid: ownDid));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, isEmpty);
      await sub.cancel();
    });
  });

  group('media type', () {
    test('emits the call with an audio media type', () async {
      when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer(
        (_) async => _channel(ownDid: ownDid, otherPartyDid: callerDid),
      );

      final emitted = <IncomingAudioVideoCallEvent>[];
      final sub = plugin.incomingCalls.listen(emitted.add);

      signalController.add(
        const IncomingCallSignal(
          ownChannelDid: ownDid,
          mediaType: CallMediaType.audio,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, hasLength(1));
      expect(emitted.single.mediaType, CallMediaType.audio);
      await sub.cancel();
    });

    test('emits the call with a video media type', () async {
      when(() => mockSdk.getChannelByDid(ownDid)).thenAnswer(
        (_) async => _channel(ownDid: ownDid, otherPartyDid: callerDid),
      );

      final emitted = <IncomingAudioVideoCallEvent>[];
      final sub = plugin.incomingCalls.listen(emitted.add);

      signalController.add(
        const IncomingCallSignal(
          ownChannelDid: ownDid,
          mediaType: CallMediaType.video,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, hasLength(1));
      expect(emitted.single.mediaType, CallMediaType.video);
      await sub.cancel();
    });
  });
}
