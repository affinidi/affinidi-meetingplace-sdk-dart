import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../meeting_place_matrix_livekit.dart'
    show MeetingPlaceLiveKitCallPlugin;
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../interfaces/livekit_room.dart';
import '../meeting_place_livekit_call_plugin.dart'
    show MeetingPlaceLiveKitCallPlugin;

part 'livekit_room_provider.g.dart';

/// Provides the [LiveKitRoom] for a call session.
///
/// This provider is overridden per-session inside the plugin's isolated
/// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
/// the global container is a configuration error.
@riverpod
LiveKitRoom livekitRoom(Ref ref, String otherPartyChannelDid) =>
    throw const MeetingPlaceLiveKitCallMisconfiguredException(
      'livekitRoomProvider must be overridden via '
      'MeetingPlaceLiveKitCallPlugin.',
    );
