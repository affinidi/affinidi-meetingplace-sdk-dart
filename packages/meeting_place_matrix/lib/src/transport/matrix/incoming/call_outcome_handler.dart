import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../call/call_event_signer.dart';
import '../../../entity/call_outcome_record.dart';
import '../../../matrix_room_event.dart';
import '../matrix_media_attachment.dart';
import 'trusted_call_start_time_store.dart';

/// Handles incoming `mpx.call.outcome` events by surfacing the canonical call
/// outcome to chat consumers as a [CallOutcomeChatEvent].
///
/// The authoritative call end time is the event's homeserver timestamp
/// (`originServerTs`), never a value trusted from the payload. An event is
/// only trusted once [MatrixEventField.callSignature] verifies against the
/// claimed sender DID, so a room member cannot report an outcome for a call
/// they were not part of; unsigned or unverifiable events are dropped. When
/// multiple verified participants post an outcome for the same call, this
/// handler applies last-write-wins by that timestamp so the truly-last
/// leaver wins and duplicate or out-of-order posts are dropped.
class CallOutcomeHandler {
  CallOutcomeHandler({
    required ChatStream chatStream,
    required MeetingPlaceChatSDKLogger logger,
    required DidResolver didResolver,
    TrustedCallStartTimeStore? startTimeStore,
    CallEventSigner callEventSigner = const CallEventSigner(),
  }) : _chatStream = chatStream,
       _logger = logger,
       _didResolver = didResolver,
       _startTimeStore = startTimeStore,
       _callEventSigner = callEventSigner;

  static const _maxRememberedCallOutcomes = 1000;

  static const _logKey = 'CallOutcomeHandler';

  final ChatStream _chatStream;
  final MeetingPlaceChatSDKLogger _logger;
  final DidResolver _didResolver;
  final TrustedCallStartTimeStore? _startTimeStore;
  final CallEventSigner _callEventSigner;
  final Map<String, DateTime> _latestEndedAtByCallId = {};

  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) {
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

    final outcomeMap = Map<String, dynamic>.from(rawOutcome);
    final record = CallOutcomeRecord.fromMap(outcomeMap);
    if (record == null) {
      _logger.warning(
        'Call outcome event ${event.id} could not be parsed, skipping.',
        name: _logKey,
      );
      return;
    }

    final signature = event.content[MatrixEventField.callSignature];
    if (signature is! String) {
      _logger.warning(
        'Call outcome event ${event.id} is unsigned, skipping.',
        name: _logKey,
      );
      return;
    }

    final isVerified = await _callEventSigner.verify(
      signature: signature,
      callFields: outcomeMap,
      senderDid: senderDid,
      didResolver: _didResolver,
    );
    if (!isVerified) {
      _logger.warning(
        'Call outcome event ${event.id} signature did not verify against '
        'claimed sender, skipping.',
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
          startedAt: _startTimeStore?[record.callId] ?? record.startedAt,
          endedAt: endedAt,
        ),
      ),
    );
  }
}
