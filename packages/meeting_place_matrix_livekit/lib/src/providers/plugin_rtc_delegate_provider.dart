import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../delegates/flutter_matrix_rtc_delegate.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';

part 'plugin_rtc_delegate_provider.g.dart';

/// Shared [FlutterMatrixRTCDelegate] instance for this call session.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`;
/// constructed by `MeetingPlaceLiveKitCallPlugin` and not exposed to the app.
@Riverpod(keepAlive: true)
FlutterMatrixRTCDelegate pluginRtcDelegate(Ref ref) =>
    throw const MeetingPlaceLiveKitCallMisconfiguredException(
      'pluginRtcDelegateProvider must be overridden via '
      'MeetingPlaceLiveKitCallPlugin.scope',
    );
