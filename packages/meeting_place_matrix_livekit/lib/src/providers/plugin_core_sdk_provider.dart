import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../exceptions/meeting_place_livekit_call_exception.dart';

part 'plugin_core_sdk_provider.g.dart';

/// [MeetingPlaceCoreSDK] instance injected into this plugin's scope.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Not part of the public API; the app injects the SDK via the plugin
/// constructor, not directly.
@Riverpod(keepAlive: true)
MeetingPlaceCoreSDK pluginCoreSdk(Ref ref) =>
    throw const MeetingPlaceLiveKitCallMisconfiguredException(
      'pluginCoreSdkProvider must be overridden via '
      'MeetingPlaceLiveKitCallPlugin.scope',
    );
