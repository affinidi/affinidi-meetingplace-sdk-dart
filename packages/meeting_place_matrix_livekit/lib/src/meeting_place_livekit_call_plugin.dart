import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'delegates/flutter_matrix_rtc_delegate.dart';
import 'exceptions/meeting_place_livekit_call_exception.dart';
import 'meeting_place_livekit_call_plugin_options.dart';
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
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className),
       _incomingCallsController =
           StreamController<IncomingAudioVideoCallEvent>.broadcast(),
       _rtcDelegate = FlutterMatrixRTCDelegate();

  final MeetingPlaceLiveKitCallPluginOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final StreamController<IncomingAudioVideoCallEvent> _incomingCallsController;
  final FlutterMatrixRTCDelegate _rtcDelegate;

  // callId -> contactId for ringing calls not yet accepted.
  final Map<String, String> _pendingCalls = {};

  // Non-null while a call is ringing or active (busy guard).
  String? _activeCallId;

  // contactId of a call accepted via acceptCall() but not yet connected via
  // startCall(). Cleared on startCall().
  String? _acceptedContactId;

  // Active session; set on startCall(), cleared on dispose.
  LiveKitCallSession? _activeSession;

  MeetingPlaceCoreSDK? _sdk;
  StreamSubscription<IncomingCallSignal>? _signalSubscription;

  static const _className = 'MeetingPlaceLiveKitCallPlugin';

  // ---------------------------------------------------------------------------
  // Plugin lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the plugin. Safe to call multiple times — idempotent.
  void initialize({required MeetingPlaceCoreSDK sdk}) {
    if (_sdk != null) return;
    _sdk = sdk;
    _signalSubscription = sdk.incomingCallSignals.listen(_onIncomingCallSignal);
    _logger.info('Plugin initialized', name: _className);
  }

  /// Disposes the plugin entirely.
  Future<void> dispose() async {
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await _incomingCallsController.close();
    _activeSession?.disposeContainer();
    _activeSession = null;
    _logger.info('Plugin disposed', name: _className);
  }

  /// Leaves the currently active call, if any.
  ///
  /// Use from app lifecycle callbacks (e.g. [AppLifecycleState.detached]) to
  /// ensure the LiveKit room is released when the app exits.
  Future<void> leaveCurrentCall() async {
    final session = _activeSession;
    if (session == null) return;
    _logger.info(
      'Leaving current call for ${session.otherPartyChannelDid.topAndTail()}',
      name: _className,
    );
    await session.hangUp();
    _activeSession?.disposeContainer();
    _activeSession = null;
  }

  // ---------------------------------------------------------------------------
  // AudioVideoCallPlugin interface
  // ---------------------------------------------------------------------------

  @override
  bool get isSupported => _options.livekitServiceUrl.host.isNotEmpty;

  @override
  Stream<IncomingAudioVideoCallEvent> get incomingCalls =>
      _incomingCallsController.stream;

  /// The currently active [AudioVideoCallSession], or null if no call is in
  /// progress.
  ///
  /// Used by the video-rendering widget (`AudioVideoCallView`) to resolve the
  /// LiveKit session. Null between calls or after `leaveCurrentCall`.
  LiveKitCallSession? get activeSession => _activeSession;

  @override
  Future<AudioVideoCallSession> startCall({required String contactId}) async {
    const methodName = 'startCall';
    final sdk = _requireSdk();

    final otherPartyChannelDid = contactId;

    // Dispose any previous session before creating a new one.
    _activeSession?.disposeContainer();
    _activeSession = null;

    final container = _buildContainer(sdk);
    final session = LiveKitCallSession.create(
      container: container,
      otherPartyChannelDid: otherPartyChannelDid,
      logger: _logger,
    );
    _activeSession = session;

    // If the user tapped Accept in the banner, _acceptedContactId is set.
    // In that case we join as callee (no call-invite nudge sent).
    final isCallee = _acceptedContactId == contactId;
    _acceptedContactId = null;

    _logger.info(
      'Starting call for ${otherPartyChannelDid.topAndTail()} '
      '(isCallee=$isCallee)',
      name: methodName,
    );

    // Trigger the LiveKit connection + (for outbound calls) the call-invite
    // nudge. The session's state stream reflects the connection progress.
    unawaited(
      container
          .read(
            audioVideoCallServiceProvider(otherPartyChannelDid).notifier,
          )
          .joinCall(isCallee: isCallee),
    );

    return session;
  }

  @override
  Future<void> acceptCall({required String callId}) async {
    const methodName = 'acceptCall';
    final contactId = _pendingCalls.remove(callId);
    if (contactId == null) {
      _logger.warning(
        'acceptCall called for unknown callId: $callId',
        name: methodName,
      );
      return;
    }
    _acceptedContactId = contactId;
    _logger.info(
      'Call $callId accepted for ${contactId.topAndTail()}',
      name: methodName,
    );
  }

  @override
  Future<void> declineCall({required String callId}) async {
    _logger.info('Call $callId declined', name: 'declineCall');
    _pendingCalls.remove(callId);
    if (_activeCallId == callId) _activeCallId = null;
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

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
    const methodName = '_emitIncomingCall';
    if (_activeCallId != null) {
      _logger.warning(
        'Incoming call ${event.callId} auto-rejected: '
        'already in call $_activeCallId',
        name: methodName,
      );
      return;
    }
    _activeCallId = event.callId;
    _pendingCalls[event.callId] = event.contactId;
    _incomingCallsController.add(event);
    _logger.info(
      'Incoming call emitted: callId=${event.callId} '
      'contactId=${event.contactId.topAndTail()}',
      name: methodName,
    );
  }

  Future<void> _onIncomingCallSignal(IncomingCallSignal signal) async {
    const methodName = '_onIncomingCallSignal';
    final sdk = _sdk;
    if (sdk == null) return;

    _logger.info(
      'Incoming call signal for ${signal.ownChannelDid.topAndTail()}',
      name: methodName,
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
          contactId: callerChannelDid,
          isAudioOnly: false,
        ),
      );
    } on MeetingPlaceLiveKitCallOperationException catch (e) {
      _logger.warning(
        'Dropping incoming call signal for'
        ' ${signal.ownChannelDid.topAndTail()}: ${e.message}',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Unexpected error handling incoming call signal for'
        ' ${signal.ownChannelDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
    }
  }
}
