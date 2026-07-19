import 'dart:async';

import '../../meeting_place_matrix.dart';
import '../call/mpx_call_event_type.dart';
import '../matrix_room_event.dart';
import '../matrix_subscription_options.dart';
import 'pending_call_manager.dart';

/// Holds active subscriptions for a pending incoming call's room membership
/// and cancel-event listeners.
class _PendingCallWatchers {
  const _PendingCallWatchers({this.membershipWatcher, this.cancelEventWatcher});

  /// Stream subscription for room membership changes.
  final StreamSubscription<void>? membershipWatcher;

  /// Stream subscription for group call cancel room events.
  final StreamSubscription<MatrixRoomEvent>? cancelEventWatcher;

  /// Cancels both subscriptions if present.
  Future<void> cancel() async {
    await membershipWatcher?.cancel();
    await cancelEventWatcher?.cancel();
  }
}

/// Parsed content of a group call cancel room event.
class _PendingGroupCallCancelEvent {
  const _PendingGroupCallCancelEvent({
    required this.callId,
    required this.callerPermanentChannelDid,
  });

  /// The MatrixRTC call ID from the cancel event, or null if not present.
  final String? callId;

  /// The caller's permanent channel DID from the cancel event, or null if not
  /// present.
  final String? callerPermanentChannelDid;
}

/// Returns true when [event]'s callId is the Matrix room ID (fallback mode).
///
/// Occurs when transport metadata is not yet stable; the room ID temporarily
/// serves as the callId until full metadata arrives.
bool _isRoomFallbackCallId(IncomingAudioVideoCallEvent event) =>
    event.roomId != null && event.callId == event.roomId;

/// Watches pending incoming calls until they are answered, cancelled, or
/// disappear from Matrix room state.
class PendingIncomingCallWatchManager {
  PendingIncomingCallWatchManager({
    required PendingCallManager pendingCallManager,
    required MeetingPlaceMatrixSDKLogger logger,
    required void Function(IncomingAudioVideoCallEvent event) onCallCancelled,
  }) : _pendingCallManager = pendingCallManager,
       _logger = logger,
       _onCallCancelled = onCallCancelled;

  final PendingCallManager _pendingCallManager;
  final MeetingPlaceMatrixSDKLogger _logger;
  final void Function(IncomingAudioVideoCallEvent event) _onCallCancelled;

  final Map<String, _PendingCallWatchers> _pendingCallWatchers = {};

  static const _logKey = 'PendingIncomingCallWatchManager';

  /// Starts watching the pending call for cancellation or room disappearance.
  ///
  /// Sets up subscriptions on the event's room for room membership changes
  /// and group call-cancel events. Cleans up any existing watchers for the same
  /// call ID. Does nothing if [sdk] is null.
  void watchPendingCall(
    MeetingPlaceMatrixSDK? sdk,
    IncomingAudioVideoCallEvent event,
  ) {
    cancelPendingCallWatcher(event.callId);
    if (sdk == null) return;

    unawaited(_startPendingCallWatchers(sdk, event));
  }

  /// Cancels watchers for the call with the given [callId].
  ///
  /// Safe to call multiple times; does nothing if no watchers exist for
  /// [callId]. Idempotent.
  void cancelPendingCallWatcher(String callId) {
    final watchers = _pendingCallWatchers.remove(callId);
    if (watchers != null) {
      unawaited(watchers.cancel());
    }
  }

  /// Cancels all active watchers and clears the internal state.
  ///
  /// Must be called when the plugin is disposed. Idempotent.
  Future<void> dispose() async {
    await Future.wait<void>(
      _pendingCallWatchers.values.map((watchers) => watchers.cancel()),
    );
    _pendingCallWatchers.clear();
  }

  /// Starts and stores watchers for the given pending call; skips if already
  /// present.
  Future<void> _startPendingCallWatchers(
    MeetingPlaceMatrixSDK sdk,
    IncomingAudioVideoCallEvent event,
  ) async {
    final watchers = await _buildPendingCallWatchers(sdk, event);
    if (watchers == null) return;
    final existing = _pendingCallWatchers[event.callId];
    if (existing != null) {
      await watchers.cancel();
      return;
    }
    _pendingCallWatchers[event.callId] = watchers;
  }

  /// Builds membership and cancel-event subscriptions for the pending call if
  /// the event's room ID is set; returns null otherwise.
  Future<_PendingCallWatchers?> _buildPendingCallWatchers(
    MeetingPlaceMatrixSDK sdk,
    IncomingAudioVideoCallEvent event,
  ) async {
    final roomId = event.roomId;
    if (roomId == null) {
      return null;
    }

    final cancelEventWatcher = await _buildGroupCallCancelWatcher(sdk, event);

    final stream = sdk.matrixService.watchIncomingCall(roomId: roomId);
    if (stream == null) {
      if (cancelEventWatcher == null) return null;
      return _PendingCallWatchers(cancelEventWatcher: cancelEventWatcher);
    }

    if (_isRoomFallbackCallId(event)) {
      return _PendingCallWatchers(cancelEventWatcher: cancelEventWatcher);
    }

    final membershipWatcher = stream.listen(
      (_) {},
      onDone: () {
        final pendingCallerDid = _pendingCallManager.otherPartyChannelDidFor(
          event.callId,
        );
        if (pendingCallerDid != event.otherPartyPermanentChannelDid) {
          return;
        }

        final removed = _pendingCallManager.removePendingByDid(
          event.otherPartyPermanentChannelDid,
        );
        if (removed == null) {
          return;
        }

        _logger.info(
          'Pending group call ${event.callId} disappeared before answer; '
          'notifying app',
          name: _logKey,
        );
        cancelPendingCallWatcher(event.callId);
        _onCallCancelled(
          IncomingAudioVideoCallEvent(
            callId: removed.callId,
            callerPermanentChannelDid: event.callerPermanentChannelDid,
            otherPartyPermanentChannelDid: event.otherPartyPermanentChannelDid,
            mediaType: removed.mediaType,
            invitedAt: event.invitedAt,
          ),
        );
      },
      onError: (_, _) => cancelPendingCallWatcher(event.callId),
      cancelOnError: true,
    );

    return _PendingCallWatchers(
      membershipWatcher: membershipWatcher,
      cancelEventWatcher: cancelEventWatcher,
    );
  }

  /// Builds a subscription to group call-cancel room events; returns null if
  /// the event's own DID or room ID is null.
  Future<StreamSubscription<MatrixRoomEvent>?> _buildGroupCallCancelWatcher(
    MeetingPlaceMatrixSDK sdk,
    IncomingAudioVideoCallEvent event,
  ) async {
    final ownDid = event.ownPermanentChannelDid;
    if (ownDid == null) return null;
    final roomId = event.roomId;
    if (roomId == null) return null;
    try {
      final didManager = await sdk.getDidManager(ownDid);
      return sdk.matrixService
          .subscribeToRoom(
            roomId,
            didManager: didManager,
            options: const MatrixSubscriptionOptions(excludeSelf: true),
          )
          .listen((roomEvent) {
            if (roomEvent.type != MpxCallEventType.callCancel) return;
            if (roomEvent.timestamp.isBefore(event.invitedAt)) return;
            final cancelEvent = _parsePendingGroupCallCancelEvent(roomEvent);
            if (!_matchesPendingGroupCallCancelEvent(event, cancelEvent)) {
              return;
            }
            final pendingCallerDid = _pendingCallManager
                .otherPartyChannelDidFor(event.callId);
            if (pendingCallerDid != event.otherPartyPermanentChannelDid) {
              return;
            }
            final removed = _pendingCallManager.removePendingByDid(
              event.otherPartyPermanentChannelDid,
            );
            if (removed == null) return;
            cancelPendingCallWatcher(event.callId);
            _onCallCancelled(
              IncomingAudioVideoCallEvent(
                callId: removed.callId,
                callerPermanentChannelDid: event.callerPermanentChannelDid,
                otherPartyPermanentChannelDid:
                    event.otherPartyPermanentChannelDid,
                mediaType: removed.mediaType,
                invitedAt: event.invitedAt,
                ownPermanentChannelDid: event.ownPermanentChannelDid,
                roomId: event.roomId,
              ),
            );
          });
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to watch group call-cancel events for ${event.callId}',
        error: error,
        stackTrace: stackTrace,
        name: _logKey,
      );
      return null;
    }
  }

  /// Extracts callId and callerPermanentChannelDid from a room event's
  /// content.
  _PendingGroupCallCancelEvent _parsePendingGroupCallCancelEvent(
    MatrixRoomEvent roomEvent,
  ) {
    final callId = roomEvent.content['callId'];
    final callerPermanentChannelDid =
        roomEvent.content['callerPermanentChannelDid'];
    return _PendingGroupCallCancelEvent(
      callId: callId is String ? callId : null,
      callerPermanentChannelDid: callerPermanentChannelDid is String
          ? callerPermanentChannelDid
          : null,
    );
  }

  /// Returns true if the parsed cancel event matches the pending call (by
  /// callId or callerPermanentChannelDid).
  bool _matchesPendingGroupCallCancelEvent(
    IncomingAudioVideoCallEvent pendingEvent,
    _PendingGroupCallCancelEvent cancelEvent,
  ) {
    final cancelCallId = cancelEvent.callId;
    if (cancelCallId == null) {
      return cancelEvent.callerPermanentChannelDid ==
          pendingEvent.callerPermanentChannelDid;
    }

    if (cancelCallId == pendingEvent.callId) {
      return true;
    }

    if (!_isRoomFallbackCallId(pendingEvent)) {
      return false;
    }

    return cancelCallId.startsWith('${pendingEvent.callId}@');
  }
}
