import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plugin_logger_provider.g.dart';

/// Logger for the MeetingPlace Matrix LiveKit plugin.
///
/// Defaults to [DefaultMeetingPlaceCoreSDKLogger]. Override in the app's
/// ProviderScope to route plugin logs through the app's own logging pipeline.
@Riverpod(keepAlive: true)
MeetingPlaceCoreSDKLogger pluginLogger(Ref ref) =>
    DefaultMeetingPlaceCoreSDKLogger(
      className: 'MeetingPlaceLiveKitCallPlugin',
    );
