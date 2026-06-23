import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/plugin_logger_provider.dart';
import '../services/livekit_service.dart';

part 'livekit_service_provider.g.dart';

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.
@riverpod
LiveKitService livekitService(Ref ref, String otherPartyChannelDid) {
  final service = LiveKitService(logger: ref.read(pluginLoggerProvider));
  ref.onDispose(() => unawaited(service.disconnect()));
  return service;
}
