import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'delegates/flutter_matrix_rtc_delegate.dart';
import 'exceptions/meeting_place_livekit_call_exception.dart';
import 'meeting_place_livekit_call_plugin_options.dart';
import 'pending_call_manager.dart';
import 'providers/plugin_core_sdk_provider.dart';
import 'providers/plugin_logger_provider.dart';
import 'providers/plugin_options_provider.dart';
import 'providers/plugin_rtc_delegate_provider.dart';
import 'services/audio_video_call_service.dart';
import 'sessions/livekit_call_session.dart';
import 'utils/string.dart';
import 'widgets/plugin_scope.dart';

/// Concrete [AudioVideoCallPlugin] backed by Matrix RTC signalling and a
/// LiveKit SFU for media transport.
///
/// Register via `audioVideoCallPluginProvider` in `main.dart`:
///
/// ```dart
/// audioVideoCallPluginProvider.overrideWith((ref) async {
///   final sdk = await ref.watch(meetingPlaceSdkProvider.future);
///   final plugin = MeetingPlaceLiveKitCallPlugin(
///     options: MeetingPlaceLiveKitCallPluginOptions(...),
///   );
///   plugin.initialize(sdk: sdk);
///   return plugin;
/// }),
/// ```
///
/// Consumers hold [AudioVideoCallPlugin] and [AudioVideoCallSession] only.
/// The concrete type is referenced exclusively in `main.dart`.
class MeetingPlaceLiveKitCallPlugin implements AudioVideoCallPlugin {
  MeetingPlaceLiveKitCallPlugin({
    required MeetingPlaceLiveKitCallPluginOptions options,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _options = options,
       _logger = logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _logKey),
       _incomingCallsController =
           StreamController<IncomingAudioVideoCallEvent>.broadcast(),
       _cancelledCallsController = StreamController<String>.broadcast(),
       _rtcDelegate = FlutterMatrixRTCDelegate();

  final MeetingPlaceLiveKitCallPluginOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final StreamController<IncomingAudioVideoCallEvent> _incomingCallsController;
  final StreamController<String> _cancelledCallsController;
  final FlutterMatrixRTCDelegate _rtcDelegate;
  final PendingCallManager _pendingCallManager = PendingCallManager();

  // Active session; set on startCall(), cleared on dispose.
  LiveKitCallSession? _activeSession;

  MeetingPlaceCoreSDK? _sdk;
  StreamSubscription<IncomingCallSignal>? _signalSubscription;
  StreamSubscription<CallDeclineSignal>? _declineSignalSubscription;

  static const _logKey = 'MeetingPlaceLiveKitCallPlugin';

  // ---------------------------------------------------------------------------
  // Plugin lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the plugin. Safe to call multiple times — idempotent.
  void initialize({required MeetingPlaceCoreSDK sdk}) {
    if (_sdk != null) {
      _logger.info(
        'initialize: already initialized, ignoring repeat call',
        name: _logKey,
      );
      return;
    }
    _sdk = sdk;
    _signalSubscription = sdk.incomingCallSignals.listen(_onIncomingCallSignal);
    _declineSignalSubscription = sdk.callDeclineSignals.listen(
      _onCallDeclineSignal,
    );
    _logger.info('Plugin initialized', name: _logKey);
  }

  /// Disposes the plugin entirely.
  Future<void> dispose() async {
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await _declineSignalSubscription?.cancel();
    _declineSignalSubscription = null;
    await _incomingCallsController.close();
    await _cancelledCallsController.close();
    _activeSession?.disposeContainer();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
    _logger.info('Plugin disposed', name: _logKey);
  }

  /// Leaves the currently active call, if any.
  ///
  /// Use from app lifecycle callbacks (e.g. [AppLifecycleState.detached]) to
  /// ensure the LiveKit room is released when the app exits.
  Future<void> leaveCurrentCall() async {
    final session = _activeSession;
    if (session == null) {
      _logger.info(
        'leaveCurrentCall: no active session to leave',
        name: _logKey,
      );
      return;
    }
    _logger.info(
      'Leaving current call for ${session.otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    await session.hangUp();
    _activeSession?.disposeContainer();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
  }

  // ---------------------------------------------------------------------------
  // AudioVideoCallPlugin interface
  // ---------------------------------------------------------------------------

  @override
  bool get isSupported => _options.livekitServiceUrl.host.isNotEmpty;

  @override
  Stream<IncomingAudioVideoCallEvent> get incomingCalls =>
      _incomingCallsController.stream;

  @override
  Stream<String> get cancelledCalls => _cancelledCallsController.stream;

  /// The currently active [AudioVideoCallSession], or null if no call is in
  /// progress.
  ///
  /// Used by the video-rendering widget (`AudioVideoCallView`) to resolve the
  /// LiveKit session. Null between calls or after `leaveCurrentCall`.
  LiveKitCallSession? get activeSession => _activeSession;

  @override
  Future<AudioVideoCallSession> startCall({
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  }) async {
    final sdk = _requireSdk();

    // Dispose any previous session before creating a new one.
    _activeSession?.disposeContainer();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();

    final container = _buildContainer(sdk);
    final session = LiveKitCallSession.create(
      container: container,
      otherPartyChannelDid: otherPartyChannelDid,
      logger: _logger,
    );
    _activeSession = session;

    final (:isRecipient, :pendingCallId) = _pendingCallManager.resolveRole(
      otherPartyChannelDid,
    );

    _logger.info(
      'startCall: ${otherPartyChannelDid.topAndTail()} '
      '(isRecipient=$isRecipient)',
      name: _logKey,
    );

    // Trigger the LiveKit connection + (for outbound calls) the call-invite
    // nudge. The session's state stream reflects the connection progress.
    unawaited(
      container
          .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
          .joinCall(isRecipient: isRecipient, mediaType: mediaType),
    );

    return session;
  }

  @override
  Future<void> acceptCall({required String callId}) async {
    final otherPartyChannelDid = _pendingCallManager.acceptCall(callId);
    if (otherPartyChannelDid == null) {
      throw MeetingPlaceLiveKitCallOperationException(
        'acceptCall: unknown callId $callId — no pending call found',
      );
    }
    _logger.info(
      'acceptCall: $callId accepted for ${otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  @override
  Future<void> declineCall({required String callId}) async {
    _logger.info('declineCall: $callId', name: _logKey);
    final callerChannelDid = _pendingCallManager.declineCall(callId);
    final sdk = _sdk;
    if (sdk != null && callerChannelDid != null) {
      unawaited(
        sdk.sendChannelNotification(
          IndividualChannelNotification(
            recipientDid: callerChannelDid,
            type: ChannelActivityType.callDecline,
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Widget scope for video rendering
  // ---------------------------------------------------------------------------

  /// Wraps [child] in the Riverpod scope for the active call session.
  ///
  /// The call screen must be a descendant of this scope so that
  /// `AudioVideoCallView` can resolve the correct `LiveKitService` instance.
  Widget scope({required Widget child}) {
    final session = _requireSession();
    return PluginScope(container: session.container, child: child);
  }

  MeetingPlaceCoreSDK _requireSdk() {
    final sdk = _sdk;
    if (sdk == null) {
      throw const MeetingPlaceLiveKitCallMisconfiguredException(
        'MeetingPlaceLiveKitCallPlugin.initialize() must be called '
        'before startCall or acceptCall.',
      );
    }
    return sdk;
  }

  LiveKitCallSession _requireSession() {
    final session = _activeSession;
    if (session == null) {
      throw const MeetingPlaceLiveKitCallMisconfiguredException(
        'No active session. Call startCall() first.',
      );
    }
    return session;
  }

  ProviderContainer _buildContainer(MeetingPlaceCoreSDK sdk) =>
      ProviderContainer(
        overrides: [
          pluginCoreSdkProvider.overrideWithValue(sdk),
          pluginOptionsProvider.overrideWithValue(_options),
          pluginRtcDelegateProvider.overrideWithValue(_rtcDelegate),
          pluginLoggerProvider.overrideWithValue(_logger),
        ],
      );

  // ---------------------------------------------------------------------------
  // Incoming call signal handling
  // ---------------------------------------------------------------------------

  void _emitIncomingCall(IncomingAudioVideoCallEvent event) {
    final registered = _pendingCallManager.registerIncomingCall(
      callId: event.callId,
      otherPartyChannelDid: event.otherPartyChannelDid,
    );
    if (!registered) {
      _logger.warning(
        'Incoming call ${event.callId} auto-rejected: already in a call',
        name: _logKey,
      );
      return;
    }
    _incomingCallsController.add(event);
    _logger.info(
      'Incoming call: callId=${event.callId} '
      'from=${event.otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  Future<void> _onIncomingCallSignal(IncomingCallSignal signal) async {
    final sdk = _sdk!;

    _logger.info(
      'Incoming call signal for ${signal.ownChannelDid.topAndTail()}',
      name: _logKey,
    );

    try {
      final channel = await sdk.getChannelByDid(signal.ownChannelDid);
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

      _emitIncomingCall(
        IncomingAudioVideoCallEvent(
          callId: callerChannelDid,
          otherPartyChannelDid: callerChannelDid,
          mediaType: signal.mediaType,
        ),
      );
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

  Future<void> _onCallDeclineSignal(CallDeclineSignal signal) async {
    _logger.info(
      'Call-decline signal for ${signal.ownChannelDid.topAndTail()}',
      name: _logKey,
    );

    String? otherPartyChannelDid;
    final sdk = _sdk;
    if (sdk != null) {
      try {
        final channel = await sdk.getChannelByDid(signal.ownChannelDid);
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
        '_onCallDeclineSignal: could not resolve other party DID, ignoring',
        name: _logKey,
      );
      return;
    }

    final session = _activeSession;
    if (session != null &&
        session.otherPartyChannelDid == otherPartyChannelDid) {
      _logger.info(
        '_onCallDeclineSignal: Callee declined outgoing call to '
        '${otherPartyChannelDid.topAndTail()}',
        name: _logKey,
      );
      session.container
          .read(
            audioVideoCallServiceProvider(
              session.otherPartyChannelDid,
            ).notifier,
          )
          .notifyDeclined();
      return;
    }

    _pendingCallManager.removePendingByDid(otherPartyChannelDid);
    _logger.info(
      '_onCallDeclineSignal: Caller ${otherPartyChannelDid.topAndTail()} '
      'cancelled before answer; notifying app',
      name: _logKey,
    );
    if (!_cancelledCallsController.isClosed) {
      _cancelledCallsController.add(otherPartyChannelDid);
    }
  }
}
