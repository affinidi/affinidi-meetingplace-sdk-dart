import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../../entity/call_outcome_record.dart';
import '../../../matrix_room_event.dart';
import '../matrix_media_attachment.dart';

/// Handles incoming `mpx.call.outcome` events by surfacing the canonical call
/// outcome to chat consumers as a [CallOutcomeChatEvent].
///
/// The authoritative call end time is the event's homeserver timestamp
/// (`originServerTs`), never a value trusted from the payload. When multiple
/// participants post an outcome for the same call, this handler applies
/// last-write-wins by that timestamp so the truly-last leaver wins and
/// duplicate or out-of-order posts are dropped.
class CallOutcomeHandler {
  CallOutcomeHandler({
    required ChatStream chatStream,
    required MeetingPlaceChatSDKLogger logger,
  }) : _chatStream = chatStream,
       _logger = logger;

  static const _maxRememberedCallOutcomes = 1000;

  static const _logKey = 'CallOutcomeHandler';

  final ChatStream _chatStream;
  final MeetingPlaceChatSDKLogger _logger;
  final Map<String, DateTime> _latestEndedAtByCallId = {};

  Future<void> handle(MatrixRoomEvent event) async {
    if (event.senderDid == null) {
      _logger.warning(
        '''Could not resolve sender DID for call outcome event ${event.id}, skipping.''',
        name: _logKey,
      );
      return;
    }

    final rawOutcome = event.content[MatrixEventField.callOutcome];
    if (rawOutcome is! Map) {
      _logger.warning(
        'Call outcome event ${event.id} has no valid record, skipping.',
        name: _logKey,
      );
      return;
    }

    final record = CallOutcomeRecord.fromMap(
      Map<String, dynamic>.from(rawOutcome),
    );
    if (record == null) {
      _logger.warning(
        'Call outcome event ${event.id} could not be parsed, skipping.',
        name: _logKey,
      );
      return;
    }

    final endedAt = event.timestamp;
    final latest = _latestEndedAtByCallId[record.callId];
    if (latest != null && !endedAt.isAfter(latest)) {
      return;
    }
    _latestEndedAtByCallId[record.callId] = endedAt;
    if (_latestEndedAtByCallId.length > _maxRememberedCallOutcomes) {
      _latestEndedAtByCallId.remove(_latestEndedAtByCallId.keys.first);
    }

    _chatStream.pushData(
      StreamData(
        event: CallOutcomeChatEvent(
          callId: record.callId,
          outcome: record.outcome.name,
          startedAt: record.startedAt,
          endedAt: endedAt,
        ),
      ),
    );
  }
}
