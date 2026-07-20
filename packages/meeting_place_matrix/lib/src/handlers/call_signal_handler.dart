import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../call/call_channel_activity_type.dart';
import '../call/incoming_call_identity.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../managers/pending_call_manager.dart';
import '../utils/string.dart';

/// Routes incoming and declined call signals from the SDK to the plugin's
/// stream controllers and active session.
///
/// Owns the channel-resolution and routing logic extracted from the plugin.
/// Constructed once per `initialize()` call with the SDK instance and callback
/// seams so the plugin itself becomes thin wiring.
class CallSignalHandler {
  CallSignalHandler({
    required MeetingPlaceMatrixSDK sdk,
    required PendingCallManager pendingCallManager,
    required MeetingPlaceMatrixSDKLogger logger,
    required LiveKitCallSession? Function() getActiveSession,
    required void Function(IncomingAudioVideoCallEvent) onIncomingCall,
    required void Function(IncomingAudioVideoCallEvent) onCallCancelled,
    required void Function(IncomingAudioVideoCallEvent) onPeerRestartedCall,
  }) : _sdk = sdk,
       _pendingCallManager = pendingCallManager,
       _logger = logger,
       _getActiveSession = getActiveSession,
       _onIncomingCall = onIncomingCall,
       _onCallCancelled = onCallCancelled,
       _onPeerRestartedCall = onPeerRestartedCall;

  final MeetingPlaceMatrixSDK _sdk;
  final PendingCallManager _pendingCallManager;
  final MeetingPlaceMatrixSDKLogger _logger;
  final LiveKitCallSession? Function() _getActiveSession;
  final void Function(IncomingAudioVideoCallEvent) _onIncomingCall;
  final void Function(IncomingAudioVideoCallEvent) _onCallCancelled;
  final void Function(IncomingAudioVideoCallEvent) _onPeerRestartedCall;

  static const _logKey = 'CallSignalHandler';

  /// Dispatches [signal] to the appropriate handler based on its runtime type.
  Future<void> handle(CallSignal signal) => switch (signal) {
    IncomingCallSignal s => onIncomingCallSignal(s),
    CallDeclineSignal s => onCallDeclineSignal(s),
  };

  /// Handles an incoming call signal from the SDK.
  ///
  /// Registers `event` with the pending-call manager before notifying the app
  /// via the `onIncomingCall` callback.
  Future<void> onIncomingCallSignal(IncomingCallSignal signal) async {
    _logger.info(
      'Incoming call signal for ${signal.ownChannelDid.topAndTail()}',
      name: _logKey,
    );

    try {
      final channel = await _sdk.getChannelByDid(signal.ownChannelDid);
      if (channel == null) {
        throw MeetingPlaceLiveKitCallOperationException(
          'No channel found for own DID ${signal.ownChannelDid.topAndTail()}',
        );
      }

      final callerChannelDid = channel.otherPartyPermanentChannelDid;
      if (callerChannelDid == null) {
        throw MeetingPlaceLiveKitCallOperationException(
          'Channel ${channel.id} has no otherPartyPermanentChannelDid',
        );
      }
      final shouldReserve = !_pendingCallManager.isBusy;
      if (shouldReserve) {
        final reserved = _pendingCallManager.reserveIncomingCall(
          callerChannelDid,
        );
        if (!reserved) {
          _logger.warning(
            'Incoming call ${callerChannelDid.topAndTail()} auto-rejected: '
            'already in a call',
            name: _logKey,
          );
          return;
        }
      }
      final identity = await _resolveIncomingCallIdentity(
        ownChannelDid: signal.ownChannelDid,
        channel: channel,
        callerChannelDid: callerChannelDid,
      );

      if (shouldReserve &&
          !_pendingCallManager.hasIncomingReservation(callerChannelDid)) {
        _logger.info(
          'Incoming call ${callerChannelDid.topAndTail()} was cancelled '
          'before banner emission',
          name: _logKey,
        );
        return;
      }

      final event = IncomingAudioVideoCallEvent(
        callId: identity.callId,
        callerPermanentChannelDid: callerChannelDid,
        otherPartyPermanentChannelDid: callerChannelDid,
        mediaType: signal.mediaType,
        invitedAt: DateTime.now().toUtc(),
        ownPermanentChannelDid: signal.ownChannelDid,
        roomId: identity.roomId,
      );
      _emitIncomingCall(event, ownChannelDid: signal.ownChannelDid);
    } on MeetingPlaceLiveKitCallOperationException catch (e) {
      _logger.warning(
        'Dropping incoming call signal for'
        ' ${signal.ownChannelDid.topAndTail()}: ${e.message}',
        name: _logKey,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Unexpected error handling incoming call signal for'
        ' ${signal.ownChannelDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }

  /// Handles a call-decline signal from the SDK.
  ///
  /// Resolves the other party's DID from `signal.ownChannelDid`. If the active
  /// session matches, notifies it directly (callee declined an outgoing call).
  /// Otherwise removes the pending call entry and notifies the app via the
  /// `onCallCancelled` callback (caller cancelled before the local user
  /// answered).
  Future<void> onCallDeclineSignal(CallDeclineSignal signal) async {
    _logger.info(
      'Call-decline signal for ${signal.ownChannelDid.topAndTail()}',
      name: _logKey,
    );

    var otherPartyChannelDid = signal.otherPartyPermanentChannelDid;
    if (otherPartyChannelDid == null) {
      try {
        final channel = await _sdk.getChannelByDid(signal.ownChannelDid);
        otherPartyChannelDid = channel?.otherPartyPermanentChannelDid;
      } catch (e, stackTrace) {
        _logger.error(
          'Failed to resolve channel for call-decline signal',
          error: e,
          stackTrace: stackTrace,
          name: _logKey,
        );
      }
    }

    if (otherPartyChannelDid == null) {
      _logger.warning(
        'onCallDeclineSignal: could not resolve other party DID, ignoring',
        name: _logKey,
      );
      return;
    }

    final session = _getActiveSession();
    if (session != null &&
        session.otherPartyChannelDid == otherPartyChannelDid) {
      _logger.info(
        'onCallDeclineSignal: Callee declined outgoing call to '
        '${otherPartyChannelDid.topAndTail()}',
        name: _logKey,
      );
      session.notifyDeclined();
      return;
    }

    final pendingCall = _pendingCallManager.removePendingByDid(
      otherPartyChannelDid,
    );
    if (pendingCall == null) {
      _pendingCallManager.cancelReservedIncomingCall(otherPartyChannelDid);
    }
    final cancelledEvent = IncomingAudioVideoCallEvent(
      callId: pendingCall?.callId ?? otherPartyChannelDid,
      callerPermanentChannelDid: otherPartyChannelDid,
      otherPartyPermanentChannelDid: signal.ownChannelDid,
      mediaType: pendingCall?.mediaType ?? CallMediaType.video,
      invitedAt: DateTime.now().toUtc(),
    );
    _logger.info(
      'onCallDeclineSignal: Caller ${otherPartyChannelDid.topAndTail()} '
      'cancelled before answer; notifying app',
      name: _logKey,
    );
    _onCallCancelled(cancelledEvent);
  }

  void _emitIncomingCall(
    IncomingAudioVideoCallEvent event, {
    required String ownChannelDid,
  }) {
    if (_pendingCallManager.isInCallWith(event.otherPartyPermanentChannelDid)) {
      final session = _getActiveSession();
      final simultaneousCall =
          session != null &&
          session.isDiallingTo(event.otherPartyPermanentChannelDid);
      if (simultaneousCall &&
          ownChannelDid.compareTo(event.otherPartyPermanentChannelDid) > 0) {
        _logger.info(
          'Incoming call ${event.callerPermanentChannelDid} from '
          '${event.otherPartyPermanentChannelDid.topAndTail()} '
          '— simultaneous call, keeping our outgoing call (we win)',
          name: _logKey,
        );
        return;
      }
      _logger.info(
        'Incoming call ${event.callerPermanentChannelDid} from '
        '${event.otherPartyPermanentChannelDid.topAndTail()} '
        '— tearing down stale call and rejoining peer',
        name: _logKey,
      );
      _onPeerRestartedCall(event);
      return;
    }
    final registered = _pendingCallManager.registerIncomingCall(
      callId: event.callId,
      otherPartyChannelDid: event.otherPartyPermanentChannelDid,
      mediaType: event.mediaType,
    );
    _pendingCallManager.releaseIncomingReservation(
      event.otherPartyPermanentChannelDid,
    );
    if (!registered) {
      _logger.warning(
        'Incoming call ${event.callerPermanentChannelDid} from '
        '${event.otherPartyPermanentChannelDid.topAndTail()} '
        'auto-rejected: already in a call',
        name: _logKey,
      );
      unawaited(
        _sdk.notifyChannel(
          IndividualChannelNotification(
            recipientDid: event.otherPartyPermanentChannelDid,
            type: CallChannelActivityType.callDecline,
          ),
        ),
      );
      // Surface busy auto-reject on the cancelled-call channel so the app can
      // record a missed call for the caller that got the busy signal.
      _onCallCancelled(
        IncomingAudioVideoCallEvent(
          callId: event.callId,
          callerPermanentChannelDid: event.callerPermanentChannelDid,
          otherPartyPermanentChannelDid: ownChannelDid,
          mediaType: event.mediaType,
          invitedAt: event.invitedAt,
        ),
      );
      return;
    }
    _onIncomingCall(event);
    _logger.info(
      'Incoming call: callId=${event.callId} '
      'from=${event.otherPartyPermanentChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  /// Resolves the incoming call ID, falling back to room ID if transport
  /// callId is not yet visible.
  Future<IncomingCallIdentity> _resolveIncomingCallIdentity({
    required String ownChannelDid,
    required Channel channel,
    required String callerChannelDid,
  }) async {
    try {
      final didManager = await _sdk.getDidManager(ownChannelDid);
      final roomId = await _sdk.matrixService.resolveRoomIdForChannel(
        didManager: didManager,
        channel: channel,
      );

      final callId = await _sdk.matrixService.activeCallId(
        didManager: didManager,
        roomId: roomId,
      );
      if (callId != null) {
        return IncomingCallIdentity(callId: callId, roomId: roomId);
      }

      _logger.info(
        'Incoming call transport callId not yet visible for '
        '${ownChannelDid.topAndTail()}, falling back to roomId $roomId',
        name: _logKey,
      );
      return IncomingCallIdentity(callId: roomId, roomId: roomId);
    } catch (e, stackTrace) {
      _logger.warning(
        'Incoming call identifier resolution failed for '
        '${ownChannelDid.topAndTail()}, falling back to caller DID '
        '${callerChannelDid.topAndTail()}',
        name: _logKey,
      );
      _logger.error(
        'Incoming call identifier resolution failed',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      return IncomingCallIdentity(callId: callerChannelDid, roomId: null);
    }
  }
}
