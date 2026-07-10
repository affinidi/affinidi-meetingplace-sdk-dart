import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../call/call_channel_activity_type.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../pending_call_manager.dart';
import '../utils/string.dart';

/// Routes incoming and declined call signals from the SDK to the plugin's
/// stream controllers and active session.
///
/// Owns the channel-resolution and routing logic extracted from the plugin.
/// Constructed once per `initialize()` call with the SDK instance and callback
/// seams so the plugin itself becomes thin wiring.
class CallSignalHandler {
  CallSignalHandler({
    required MeetingPlaceCoreSDK sdk,
    required PendingCallManager pendingCallManager,
    required MeetingPlaceMatrixSDKLogger logger,
    required LiveKitCallSession? Function() getActiveSession,
    required void Function(IncomingAudioVideoCallEvent) onIncomingCall,
    required void Function(String otherPartyPermanentChannelDid)
    onCallCancelled,
    required void Function(IncomingAudioVideoCallEvent) onPeerRestartedCall,
  }) : _sdk = sdk,
       _pendingCallManager = pendingCallManager,
       _logger = logger,
       _getActiveSession = getActiveSession,
       _onIncomingCall = onIncomingCall,
       _onCallCancelled = onCallCancelled,
       _onPeerRestartedCall = onPeerRestartedCall;

  final MeetingPlaceCoreSDK _sdk;
  final PendingCallManager _pendingCallManager;
  final MeetingPlaceMatrixSDKLogger _logger;
  final LiveKitCallSession? Function() _getActiveSession;
  final void Function(IncomingAudioVideoCallEvent) _onIncomingCall;
  final void Function(String) _onCallCancelled;
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

      final event = IncomingAudioVideoCallEvent(
        callerPermanentChannelDid: callerChannelDid,
        otherPartyPermanentChannelDid: callerChannelDid,
        mediaType: signal.mediaType,
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

    String? otherPartyChannelDid;
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

    _pendingCallManager.removePendingByDid(otherPartyChannelDid);
    _logger.info(
      'onCallDeclineSignal: Caller ${otherPartyChannelDid.topAndTail()} '
      'cancelled before answer; notifying app',
      name: _logKey,
    );
    _onCallCancelled(otherPartyChannelDid);
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
      callId: event.callerPermanentChannelDid,
      otherPartyChannelDid: event.otherPartyPermanentChannelDid,
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
      return;
    }
    _onIncomingCall(event);
    _logger.info(
      'Incoming call: callId=${event.callerPermanentChannelDid} '
      'from=${event.otherPartyPermanentChannelDid.topAndTail()}',
      name: _logKey,
    );
  }
}
