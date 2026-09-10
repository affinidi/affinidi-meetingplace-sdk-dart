/// @docImport 'call_outcome_handler.dart';
library;

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../call/call_event_signer.dart';
import '../../../matrix_room_event.dart';
import '../matrix_media_attachment.dart';
import 'trusted_call_start_time_store.dart';

/// Handles incoming `mpx.call.started` events by recording the trustworthy
/// call start time in [TrustedCallStartTimeStore].
///
/// The authoritative call start time is the event's homeserver timestamp
/// (`originServerTs`), never a value from the payload. An event is only
/// trusted once [MatrixEventField.callSignature] verifies against the
/// claimed sender DID, so a room member cannot plant a start time for a
/// call they did not start; unsigned or unverifiable events are dropped.
/// Produces no chat event of its own; [CallOutcomeHandler] reads the stored
/// value when the matching `mpx.call.outcome` event arrives.
class CallStartedHandler {
  CallStartedHandler({
    required TrustedCallStartTimeStore startTimeStore,
    required MeetingPlaceChatSDKLogger logger,
    required DidResolver didResolver,
    CallEventSigner callEventSigner = const CallEventSigner(),
  }) : _startTimeStore = startTimeStore,
       _logger = logger,
       _didResolver = didResolver,
       _callEventSigner = callEventSigner;

  static const _logKey = 'CallStartedHandler';

  final TrustedCallStartTimeStore _startTimeStore;
  final MeetingPlaceChatSDKLogger _logger;
  final DidResolver _didResolver;
  final CallEventSigner _callEventSigner;

  Future<void> handle(MatrixRoomEvent event) async {
    final callId = event.content[MatrixEventField.callId];
    if (callId is! String || callId.isEmpty) {
      _logger.warning(
        'Call started event ${event.id} has no valid callId, skipping.',
        name: _logKey,
      );
      return;
    }

    final senderDid = event.senderDid;
    final signature = event.content[MatrixEventField.callSignature];
    if (senderDid == null || signature is! String) {
      _logger.warning(
        'Call started event ${event.id} is unsigned or has no resolved '
        'sender DID, skipping.',
        name: _logKey,
      );
      return;
    }

    final isVerified = await _callEventSigner.verify(
      signature: signature,
      callFields: {MatrixEventField.callId: callId},
      senderDid: senderDid,
      didResolver: _didResolver,
    );
    if (!isVerified) {
      _logger.warning(
        'Call started event ${event.id} signature did not verify against '
        'claimed sender, skipping.',
        name: _logKey,
      );
      return;
    }

    _startTimeStore.recordIfAbsent(callId, event.timestamp);
  }
}
