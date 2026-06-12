import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_core/meeting_place_core.dart'
    show IncomingCallSignal;
import 'package:meeting_place_matrix_livekit/meeting_place_matrix_livekit.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_core_sdk_provider.dart';
import 'package:meeting_place_matrix_livekit/src/providers/plugin_options_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mocks.dart';

MeetingPlaceLiveKitCallPlugin _plugin({Uri? livekitServiceUrl}) =>
    MeetingPlaceLiveKitCallPlugin(
      options: MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl:
            livekitServiceUrl ?? Uri.parse('https://livekit.example.com'),
      ),
    );

MockMeetingPlaceCoreSDK _mockSdk() {
  final sdk = MockMeetingPlaceCoreSDK();
  when(
    () => sdk.incomingCallSignals,
  ).thenAnswer((_) => const Stream<IncomingCallSignal>.empty());
  return sdk;
}

void main() {
  group('isSupported', () {
    test('returns true when livekitServiceUrl host is non-empty', () {
      final plugin = _plugin(
        livekitServiceUrl: Uri.parse('https://livekit.example.com'),
      );
      expect(plugin.isSupported, isTrue);
    });

    test('returns false when livekitServiceUrl host is empty', () {
      final plugin = _plugin(livekitServiceUrl: Uri());
      expect(plugin.isSupported, isFalse);
    });
  });

  group('incomingCalls', () {
    test('is a broadcast stream — multiple listeners do not throw', () {
      final plugin = _plugin();
      final stream = plugin.incomingCalls;

      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      addTearDown(() {
        sub1.cancel();
        sub2.cancel();
      });
    });
  });

  group('scope()', () {
    testWidgets('wires pluginCoreSdkProvider to the given SDK', (tester) async {
      final options = MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl: Uri.parse('https://livekit.example.com'),
      );
      final plugin = MeetingPlaceLiveKitCallPlugin(options: options);
      final sdk = _mockSdk();
      plugin.initialize(sdk: sdk);
      addTearDown(plugin.disposeCall);

      Object? readSdk;

      await tester.pumpWidget(
        plugin.scope(
          child: Consumer(
            builder: (context, ref, _) {
              readSdk = ref.read(pluginCoreSdkProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(readSdk, same(sdk));
    });

    testWidgets('wires pluginOptionsProvider to the given options', (
      tester,
    ) async {
      final options = MeetingPlaceLiveKitCallPluginOptions(
        livekitServiceUrl: Uri.parse('https://livekit.example.com'),
      );
      final plugin = MeetingPlaceLiveKitCallPlugin(options: options);
      plugin.initialize(sdk: _mockSdk());
      addTearDown(plugin.disposeCall);

      Object? readOptions;

      await tester.pumpWidget(
        plugin.scope(
          child: Consumer(
            builder: (context, ref, _) {
              readOptions = ref.read(pluginOptionsProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(readOptions, same(options));
    });

    testWidgets('overrides pluginLoggerProvider when logger is provided', (
      tester,
    ) async {
      final logger = MockMeetingPlaceCoreSDKLogger();
      final plugin = MeetingPlaceLiveKitCallPlugin(
        options: MeetingPlaceLiveKitCallPluginOptions(
          livekitServiceUrl: Uri.parse('https://livekit.example.com'),
        ),
        logger: logger,
      );
      plugin.initialize(sdk: _mockSdk());
      addTearDown(plugin.disposeCall);

      Object? readLogger;

      await tester.pumpWidget(
        plugin.scope(
          child: Consumer(
            builder: (context, ref, _) {
              readLogger = ref.read(pluginLoggerProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(readLogger, same(logger));
    });
  });

  group('acceptCall', () {
    test('completes without throwing for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(plugin.acceptCall(callId: 'unknown-call'), completes);
    });
  });

  group('declineCall', () {
    test('completes without throwing for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(plugin.declineCall(callId: 'unknown-call'), completes);
    });
  });

  group('endCall', () {
    test('completes without throwing for an unknown callId', () async {
      final plugin = _plugin();
      await expectLater(plugin.endCall(callId: 'unknown-call'), completes);
    });
  });

  group('onCallEnded', () {
    test('does not throw when callId is not the active call', () {
      final plugin = _plugin();
      expect(() => plugin.onCallEnded('no-active-call'), returnsNormally);
    });
  });
}
