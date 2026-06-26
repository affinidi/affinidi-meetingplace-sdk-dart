import 'package:matrix/matrix.dart' as matrix;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../meeting_place_matrix_livekit.dart'
    show MeetingPlaceLiveKitCallPlugin;
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../meeting_place_livekit_call_plugin.dart'
    show MeetingPlaceLiveKitCallPlugin;

part 'plugin_rtc_delegate_provider.g.dart';

/// Shared [matrix.WebRTCDelegate] instance for this call session.
///
/// Overridden in the plugin's isolated [ProviderContainer] by
/// [MeetingPlaceLiveKitCallPlugin] at session creation time.
@Riverpod(keepAlive: true)
matrix.WebRTCDelegate pluginRtcDelegate(Ref ref) =>
    throw const MeetingPlaceLiveKitCallMisconfiguredException(
      'pluginRtcDelegateProvider must be overridden via '
      'MeetingPlaceLiveKitCallPlugin.',
    );
