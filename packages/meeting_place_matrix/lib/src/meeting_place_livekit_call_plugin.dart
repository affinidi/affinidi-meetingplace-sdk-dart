import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_matrix.dart';
import 'handlers/call_signal_handler.dart';
import 'pending_call_manager.dart';
import 'services/sfu_token_service.dart';
import 'utils/string.dart';

/// Factory that produces a [LiveKitRoom] for a given call session.
typedef LiveKitRoomFactory = LiveKitRoom Function(String otherPartyChannelDid);

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
    required matrix.WebRTCDelegate rtcDelegate,
    required LiveKitRoomFactory roomFactory,
    MeetingPlaceMatrixSDKLogger? logger,
  }) : _options = options,
       _rtcDelegate = rtcDelegate,
       _roomFactory = roomFactory,
       _logger =
           logger ?? DefaultMeetingPlaceMatrixSDKLogger(className: _logKey),
       _incomingCallsController =
           StreamController<IncomingAudioVideoCallEvent>.broadcast(),
       _cancelledCallsController = StreamController<String>.broadcast();

  final MeetingPlaceLiveKitCallPluginOptions _options;
  final MeetingPlaceMatrixSDKLogger _logger;
  final StreamController<IncomingAudioVideoCallEvent> _incomingCallsController;
  final StreamController<String> _cancelledCallsController;
  final matrix.WebRTCDelegate _rtcDelegate;
  final LiveKitRoomFactory _roomFactory;
  final PendingCallManager _pendingCallManager = PendingCallManager();

  // Active session; set on startCall(), cleared on dispose.
  LiveKitCallSession? _activeSession;

  MeetingPlaceMatrixSDK? _sdk;
  CallSignalHandler? _signalHandler;
  StreamSubscription<IncomingCallSignal>? _signalSubscription;
  StreamSubscription<CallDeclineSignal>? _declineSignalSubscription;

  static const _logKey = 'MeetingPlaceLiveKitCallPlugin';

  // ---------------------------------------------------------------------------
  // Plugin lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the plugin. Safe to call multiple times — idempotent.
  void initialize({required MeetingPlaceMatrixSDK sdk}) {
    if (_sdk != null) {
      _logger.info(
        'initialize: already initialized, ignoring repeat call',
        name: _logKey,
      );
      return;
    }
    _sdk = sdk;
    _signalHandler = CallSignalHandler(
      sdk: sdk,
      pendingCallManager: _pendingCallManager,
      logger: _logger,
      getActiveSession: () => _activeSession,
      onIncomingCall: (event) {
        if (!_incomingCallsController.isClosed) {
          _incomingCallsController.add(event);
        }
      },
      onCallCancelled: (otherPartyChannelDid) {
        if (!_cancelledCallsController.isClosed) {
          _cancelledCallsController.add(otherPartyChannelDid);
        }
      },
    );
    _signalSubscription = sdk.incomingCallSignals.listen(
      _signalHandler!.onIncomingCallSignal,
    );
    _declineSignalSubscription = sdk.callDeclineSignals.listen(
      _signalHandler!.onCallDeclineSignal,
    );
    _logger.info('Plugin initialized', name: _logKey);
  }

  /// Disposes the plugin entirely.
  Future<void> dispose() async {
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await _declineSignalSubscription?.cancel();
    _declineSignalSubscription = null;
    _signalHandler = null;
    await _incomingCallsController.close();
    await _cancelledCallsController.close();
    await _activeSession?.dispose();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
    _logger.info('Plugin disposed', name: _logKey);
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
    if (_activeSession != null) {
      _logger.warning(
        'startCall: disposing previous active session for '
        '${_activeSession!.otherPartyChannelDid.topAndTail()}',
        name: _logKey,
      );
      unawaited(_activeSession!.dispose());
      _activeSession = null;
      _pendingCallManager.clearActiveCall();
    }

    final session = _buildSession(
      sdk: sdk,
      otherPartyChannelDid: otherPartyChannelDid,
    );
    _activeSession = session;
    _watchForSessionEnd(session);

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
    unawaited(session.joinCall(isRecipient: isRecipient, mediaType: mediaType));

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
        sdk.notifyChannel(
          IndividualChannelNotification(
            recipientDid: callerChannelDid,
            type: CallChannelActivityType.callDecline,
          ),
        ),
      );
    }
  }

  /// Leaves the currently active call, if any.
  ///
  /// Use from app lifecycle callbacks to ensure the LiveKit room is released
  /// when the app exits.
  @override
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
    await _activeSession?.dispose();
    _activeSession = null;
    _pendingCallManager.clearActiveCall();
  }

  MeetingPlaceMatrixSDK _requireSdk() {
    final sdk = _sdk;
    if (sdk == null) {
      throw const MeetingPlaceLiveKitCallMisconfiguredException(
        'MeetingPlaceLiveKitCallPlugin.initialize() must be called '
        'before startCall or acceptCall.',
      );
    }
    return sdk;
  }

  // Subscribes to [session]'s state stream and auto-clears [_activeSession]
  // and [_pendingCallManager] when a call-end status is emitted.
  //
  // This ensures the busy guard is released regardless of whether the call ends
  // via the user hanging up, a remote hang-up, or a timeout — without requiring
  // the app to call [leaveCurrentCall] on every code path.
  void _watchForSessionEnd(LiveKitCallSession session) {
    const endedStatuses = {
      AudioVideoCallStatus.ended,
      AudioVideoCallStatus.declined,
      AudioVideoCallStatus.missed,
      AudioVideoCallStatus.disconnected,
      AudioVideoCallStatus.error,
    };

    void release(String reason) {
      if (_activeSession == session) {
        _logger.info(
          'watchForSessionEnd: $reason — releasing busy guard for '
          '${session.otherPartyChannelDid.topAndTail()}',
          name: _logKey,
        );
        _activeSession = null;
        _pendingCallManager.clearActiveCall();
      }
    }

    session.state
        .where((s) => endedStatuses.contains(s.status))
        .listen(
          (_) => release('call ended'),
          onDone: () => release('session stream closed'),
          onError: (_) => release('session stream error'),
          cancelOnError: true,
        );
  }

  LiveKitCallSession _buildSession({
    required MeetingPlaceMatrixSDK sdk,
    required String otherPartyChannelDid,
  }) {
    final tokenService = SfuTokenService(
      serviceUrl: _options.livekitServiceUrl,
      logger: _logger,
    );
    final room = _roomFactory(otherPartyChannelDid);
    final service = AudioVideoCallService(
      otherPartyChannelDid: otherPartyChannelDid,
      sdk: sdk,
      options: _options,
      rtcDelegate: _rtcDelegate,
      logger: _logger,
      livekitTokenService: tokenService,
      room: room,
    );
    return LiveKitCallSession.create(
      service: service,
      otherPartyChannelDid: otherPartyChannelDid,
      logger: _logger,
    );
  }
}
