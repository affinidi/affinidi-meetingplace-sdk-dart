import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_matrix.dart';
import 'call/call_channel_activity_type.dart';
import 'handlers/call_signal_handler.dart';
import 'managers/active_call_session_manager.dart';
import 'managers/pending_call_manager.dart';
import 'managers/pending_incoming_call_watch_manager.dart';
import 'services/audio_video_call_service.dart';
import 'services/sfu_token_service.dart';
import 'transport/matrix/call/contracts/audio_video_call_plugin.dart';
import 'utils/string.dart';

/// Factory that produces a [LiveKitRoom] for a given call session.
typedef LiveKitRoomFactory = LiveKitRoom Function(String otherPartyChannelDid);

/// Concrete [AudioVideoCallPlugin] backed by Matrix RTC signalling and a
/// LiveKit SFU for media transport.
///
/// Construct the plugin and pass it alongside the [MeetingPlaceMatrixSDK]
/// when calling [MeetingPlaceMatrixSDK.create].  The SDK will call
/// [initialize] automatically; consumers never need to call it directly.
class MeetingPlaceLiveKitCallPlugin implements AudioVideoCallPlugin {
  MeetingPlaceLiveKitCallPlugin({
    required Uri livekitServiceUrl,
    Uri? livekitSfuUrl,
    List<String> sfuAllowedHosts = const [],
    Duration outgoingCallTimeout = const Duration(seconds: 60),
    Duration e2eeReadyTimeout = const Duration(seconds: 10),
    required matrix.WebRTCDelegate rtcDelegate,
    required LiveKitRoomFactory roomFactory,
    MeetingPlaceMatrixSDKLogger? logger,
  }) : _livekitServiceUrl = livekitServiceUrl,
       _livekitSfuUrl = livekitSfuUrl,
       _sfuAllowedHosts = sfuAllowedHosts,
       _outgoingCallTimeout = outgoingCallTimeout,
       _e2eeReadyTimeout = e2eeReadyTimeout,
       _rtcDelegate = rtcDelegate,
       _roomFactory = roomFactory,
       _logger =
           logger ?? DefaultMeetingPlaceMatrixSDKLogger(className: _logKey),
       _incomingCallsController =
           StreamController<IncomingAudioVideoCallEvent>.broadcast(),
       _cancelledCallsController =
           StreamController<IncomingAudioVideoCallEvent>.broadcast() {
    _activeCallSessionManager = ActiveCallSessionManager(
      pendingCallManager: _pendingCallManager,
      logger: _logger,
    );
    _pendingIncomingCallWatchManager = PendingIncomingCallWatchManager(
      pendingCallManager: _pendingCallManager,
      logger: _logger,
      onCallCancelled: (event) {
        if (!_cancelledCallsController.isClosed) {
          _cancelledCallsController.add(event);
        }
      },
    );
    if (_livekitSfuUrl == null && _sfuAllowedHosts.isEmpty) {
      throw const MeetingPlaceLiveKitCallMisconfiguredException(
        'sfuAllowedHosts must be non-empty in production mode '
        '(livekitSfuUrl is null) to prevent SFU URL hijacking',
      );
    }
  }

  final Uri _livekitServiceUrl;
  final Uri? _livekitSfuUrl;
  final List<String> _sfuAllowedHosts;
  final Duration _outgoingCallTimeout;
  final Duration _e2eeReadyTimeout;
  final MeetingPlaceMatrixSDKLogger _logger;
  final StreamController<IncomingAudioVideoCallEvent> _incomingCallsController;
  final StreamController<IncomingAudioVideoCallEvent> _cancelledCallsController;
  final matrix.WebRTCDelegate _rtcDelegate;
  final LiveKitRoomFactory _roomFactory;
  final PendingCallManager _pendingCallManager = PendingCallManager();
  late final ActiveCallSessionManager _activeCallSessionManager;
  late final PendingIncomingCallWatchManager _pendingIncomingCallWatchManager;

  MeetingPlaceMatrixSDK? _sdk;
  CallSignalHandler? _signalHandler;
  StreamSubscription<CallSignal>? _signalSubscription;

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
      getActiveSession: () => _activeCallSessionManager.activeSession,
      onIncomingCall: (event) {
        _pendingIncomingCallWatchManager.watchPendingCall(_sdk, event);
        if (!_incomingCallsController.isClosed) {
          _incomingCallsController.add(event);
        }
      },
      onCallCancelled: (event) {
        _pendingIncomingCallWatchManager.cancelPendingCallWatcher(event.callId);
        if (!_cancelledCallsController.isClosed) {
          _cancelledCallsController.add(event);
        }
      },
      onPeerRestartedCall: (event) {
        _logger.info(
          'Peer restarted from '
          '${event.otherPartyPermanentChannelDid.topAndTail()}',
          name: _logKey,
        );
        final previousSession = _activeCallSessionManager.activeSession;
        _activeCallSessionManager.clearActiveSession();
        _pendingCallManager.registerIncomingCall(
          callId: event.callId,
          otherPartyChannelDid: event.otherPartyPermanentChannelDid,
          mediaType: event.mediaType,
        );
        _pendingIncomingCallWatchManager.watchPendingCall(_sdk, event);
        if (!_incomingCallsController.isClosed) {
          _incomingCallsController.add(event);
        }
        if (previousSession != null) {
          _activeCallSessionManager.disposeSessionAfterPeerRestart(
            previousSession,
          );
        }
      },
    );
    _signalSubscription = sdk.callSignals.listen(_signalHandler!.handle);
    _logger.info('Plugin initialized', name: _logKey);
  }

  /// Disposes the plugin entirely.
  Future<void> dispose() async {
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    _signalHandler = null;
    await _pendingIncomingCallWatchManager.dispose();
    await _incomingCallsController.close();
    await _cancelledCallsController.close();
    await _activeCallSessionManager.dispose();
    _logger.info('Plugin disposed', name: _logKey);
  }

  // ---------------------------------------------------------------------------
  // AudioVideoCallPlugin interface
  // ---------------------------------------------------------------------------

  @override
  bool get isSupported => _livekitServiceUrl.host.isNotEmpty;

  @override
  Stream<IncomingAudioVideoCallEvent> get incomingCalls =>
      _incomingCallsController.stream;

  @override
  Stream<IncomingAudioVideoCallEvent> get cancelledCalls =>
      _cancelledCallsController.stream;

  /// The currently active [AudioVideoCallSession], or null if no call is in
  /// progress.
  ///
  /// Used by the video-rendering widget (`AudioVideoCallView`) to resolve the
  /// LiveKit session. Null between calls or after `leaveCurrentCall`.
  LiveKitCallSession? get activeSession =>
      _activeCallSessionManager.activeSession;

  @override
  Future<AudioVideoCallSession> startCall({
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  }) async {
    await _activeCallSessionManager.awaitPendingDisposal();

    final sdk = _requireSdk();

    await _activeCallSessionManager.disposeCurrentSessionForReplacement();

    final session = _buildSession(
      sdk: sdk,
      otherPartyChannelDid: otherPartyChannelDid,
    );
    _activeCallSessionManager.setActiveSession(session);

    final (:isRecipient, :pendingCallId) = _pendingCallManager.resolveRole(
      otherPartyChannelDid,
    );

    if (!isRecipient) {
      _pendingCallManager.markOutboundCall(otherPartyChannelDid);
    }

    _logger.info(
      'startCall: ${otherPartyChannelDid.topAndTail()} '
      '(isRecipient=$isRecipient)',
      name: _logKey,
    );

    unawaited(session.joinCall(isRecipient: isRecipient, mediaType: mediaType));

    return session;
  }

  @override
  Future<void> acceptCall({required String callId}) async {
    final otherPartyChannelDid = _pendingCallManager.acceptCall(callId);
    _pendingIncomingCallWatchManager.cancelPendingCallWatcher(callId);
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
    _pendingIncomingCallWatchManager.cancelPendingCallWatcher(callId);
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
    await _activeCallSessionManager.leaveCurrentCall();
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

  LiveKitCallSession _buildSession({
    required MeetingPlaceMatrixSDK sdk,
    required String otherPartyChannelDid,
  }) {
    final tokenService = SfuTokenService(
      serviceUrl: _livekitServiceUrl,
      logger: _logger,
    );
    final room = _roomFactory(otherPartyChannelDid);
    final service = AudioVideoCallService(
      otherPartyChannelDid: otherPartyChannelDid,
      sdk: sdk,
      livekitSfuUrl: _livekitSfuUrl,
      sfuAllowedHosts: _sfuAllowedHosts,
      e2eeReadyTimeout: _e2eeReadyTimeout,
      outgoingCallTimeout: _outgoingCallTimeout,
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
