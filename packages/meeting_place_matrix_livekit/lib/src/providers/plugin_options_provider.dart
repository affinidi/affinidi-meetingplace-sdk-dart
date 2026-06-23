import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../meeting_place_livekit_call_plugin_options.dart';

part 'plugin_options_provider.g.dart';

/// Plugin-wide options (includes `livekitServiceUrl`).
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Internal; the app sets options via the plugin constructor.
@Riverpod(keepAlive: true)
MeetingPlaceLiveKitCallPluginOptions pluginOptions(Ref ref) =>
    throw const MeetingPlaceLiveKitCallMisconfiguredException(
      'pluginOptionsProvider must be overridden via '
      'MeetingPlaceLiveKitCallPlugin.scope',
    );
