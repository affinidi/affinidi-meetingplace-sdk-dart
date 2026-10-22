/// @docImport 'call_outcome_handler.dart';
library;

import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../../matrix_room_event.dart';
import '../matrix_media_attachment.dart';
import 'trusted_call_start_time_store.dart';

/// Handles incoming `mpx.call.started` events by recording the trustworthy
/// call start time in [TrustedCallStartTimeStore].
///
/// The authoritative call start time is the event's homeserver timestamp
/// (`originServerTs`), never a value from the payload. Produces no chat
/// event of its own; [CallOutcomeHandler] reads the stored value when the
/// matching `mpx.call.outcome` event arrives.
class CallStartedHandler {
  CallStartedHandler({
    required TrustedCallStartTimeStore startTimeStore,
    required MeetingPlaceChatSDKLogger logger,
  }) : _startTimeStore = startTimeStore,
       _logger = logger;

  static const _logKey = 'CallStartedHandler';

  final TrustedCallStartTimeStore _startTimeStore;
  final MeetingPlaceChatSDKLogger _logger;

  Future<void> handle(MatrixRoomEvent event) async {
    final callId = event.content[MatrixEventField.callId];
    if (callId is! String || callId.isEmpty) {
      _logger.warning(
        'Call started event ${event.id} has no valid callId, skipping.',
        name: _logKey,
      );
      return;
    }

    _startTimeStore.recordIfAbsent(callId, event.timestamp);
  }
}
