import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallSession, AudioVideoCallState;
import 'package:meeting_place_matrix_livekit/src/providers/livekit_service_provider.dart';
import 'package:meeting_place_matrix_livekit/src/services/audio_video_call_service.dart';
import 'package:meeting_place_matrix_livekit/src/sessions/livekit_call_session.dart';
import 'package:meeting_place_matrix_livekit/src/widgets/audio_video_call_view.dart';
import 'package:meeting_place_matrix_livekit/src/widgets/plugin_scope.dart';

import '../fakes/fake_livekit_service.dart';
import '../mocks/mocks.dart';

class _FakeSession extends Fake implements AudioVideoCallSession {}

class _StubAudioVideoCallService extends AudioVideoCallService {
  @override
  AudioVideoCallState build(String otherPartyChannelDid) =>
      AudioVideoCallState.initial;
}

const _otherPartyDid = 'did:key:view-test-other';

ProviderContainer _buildSessionContainer() {
  final fakeService = FakeLiveKitService();
  return ProviderContainer(
    overrides: [
      audioVideoCallServiceProvider(
        _otherPartyDid,
      ).overrideWith(_StubAudioVideoCallService.new),
      livekitServiceProvider(_otherPartyDid).overrideWith((ref) => fakeService),
    ],
  );
}

void main() {
  group('non-LiveKit session', () {
    testWidgets('renders SizedBox.shrink for a non-LiveKit session', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Center(
            child: AudioVideoCallView(
              session: _FakeSession(),
              participantId: 'p1',
            ),
          ),
        ),
      );
      await tester.pump();

      // Non-LiveKit sessions must never mount a PluginScope.
      expect(find.byType(PluginScope), findsNothing);
    });
  });

  group('LiveKit session', () {
    testWidgets(
      'renders SizedBox.shrink when the participant has no video track',
      (tester) async {
        final sessionContainer = _buildSessionContainer();
        final logger = MockMeetingPlaceCoreSDKLogger();

        final session = LiveKitCallSession.create(
          container: sessionContainer,
          otherPartyChannelDid: _otherPartyDid,
          logger: logger,
        );

        addTearDown(session.disposeContainer);

        await tester.pumpWidget(
          Center(
            child: AudioVideoCallView(session: session, participantId: 'p1'),
          ),
        );
        await tester.pump();

        // LiveKit session must mount a PluginScope for the video view scope.
        expect(find.byType(PluginScope), findsOneWidget);

        // Dispose and flush Riverpod's auto-dispose timer before the test ends.
        session.disposeContainer();
        await tester.pump(Duration.zero);
      },
    );
  });
}
