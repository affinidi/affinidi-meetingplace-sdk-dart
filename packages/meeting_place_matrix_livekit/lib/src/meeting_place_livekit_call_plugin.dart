import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../meeting_place_matrix_livekit.dart' show MeetingPlaceLiveKitVideoView;
import 'delegates/flutter_matrix_rtc_delegate.dart';
import 'exceptions/meeting_place_livekit_call_exception.dart';
import 'meeting_place_livekit_call_plugin_options.dart';
import 'providers/plugin_core_sdk_provider.dart';
import 'providers/plugin_logger_provider.dart';
import 'providers/plugin_options_provider.dart';
import 'providers/plugin_rtc_delegate_provider.dart';
import 'services/audio_video_call_service.dart';
import 'services/audio_video_call_service_state.dart';
import 'utils/string.dart';
import 'widgets/meeting_place_livekit_video_view.dart'
    show MeetingPlaceLiveKitVideoView;
import 'widgets/plugin_scope.dart';

class MeetingPlaceLiveKitCallPlugin implements AudioVideoCallPlugin {
  MeetingPlaceLiveKitCallPlugin({
    required MeetingPlaceLiveKitCallPluginOptions options,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _options = options,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className),
       _incomingCallsController =
           StreamController<IncomingCallEvent>.broadcast(),
       _rtcDelegate = FlutterMatrixRTCDelegate();

  final MeetingPlaceLiveKitCallPluginOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final StreamController<IncomingCallEvent> _incomingCallsController;
  final FlutterMatrixRTCDelegate _rtcDelegate;
  // callId → contactId for active incoming calls.
  // Populated by _emitIncomingCall; consumed by acceptCall / declineCall.
  final Map<String, String> _pendingCalls = {};
  // Non-null while a call is ringing or active.
  // Any new invite that arrives while this is set is auto-rejected (busy).
  String? _activeCallId;
  // otherPartyChannelDid of the current outgoing call, set on joinCall,
  // cleared on disposeCall. Used by leaveCurrentCall() to clean up on app
  // lifecycle events.
  String? _activeOtherPartyChannelDid;
  // SDK reference and subscription for incoming call signals.
  // Both set once in initialize() and never changed.
  MeetingPlaceCoreSDK? _sdk;
  StreamSubscription<IncomingCallSignal>? _signalSubscription;

  /// Plugin-owned container — created on first [initialize] call.
  /// Holds all scoped plugin providers (service, livekit, etc.) for the
  /// duration of the call. App-layer code reads state through [callState]
  /// and imperative methods on this class; no Riverpod dependency annotation
  /// is required in the consumer.
  ProviderContainer? _container;

  static const _className = 'MeetingPlaceLiveKitCallPlugin';

  @override
  bool get isSupported => _options.livekitServiceUrl.host.isNotEmpty;

  @override
  Stream<IncomingCallEvent> get incomingCalls =>
      _incomingCallsController.stream;

  // ---------------------------------------------------------------------------
  // Container lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the plugin-owned container.
  ///
  /// Must be called before `callState`, `joinCall`, `leaveCall`, or any other
  /// imperative method. Safe to call multiple times — subsequent calls are
  /// no-ops. Call `disposeCall` when the call is over to release resources.
  void initialize({required MeetingPlaceCoreSDK sdk}) {
    const methodName = 'initialize';
    if (_container != null) {
      _logger.info('Container already initialized, skipping', name: methodName);
      return;
    }
    _sdk = sdk;
    _signalSubscription = sdk.incomingCallSignals.listen(_onIncomingCallSignal);
    _container = ProviderContainer(
      overrides: [
        pluginCoreSdkProvider.overrideWithValue(sdk),
        pluginOptionsProvider.overrideWithValue(_options),
        pluginRtcDelegateProvider.overrideWithValue(_rtcDelegate),
        pluginLoggerProvider.overrideWithValue(_logger),
      ],
    );
    _logger.info('Container created', name: methodName);
  }

  /// Disposes the plugin-owned container, releasing all call resources.
  ///
  /// Call after the call screen is dismissed.
  void disposeCall() {
    const methodName = 'disposeCall';
    if (_container == null) {
      _logger.warning('No active container to dispose', name: methodName);
      return;
    }
    _container?.dispose();
    _container = null;
    _activeCallId = null;
    _activeOtherPartyChannelDid = null;
    _logger.info('Container disposed', name: methodName);
  }

  /// Disposes the plugin entirely, cancelling the incoming-call signal
  /// subscription and closing the incoming-calls stream.
  ///
  /// Call when the app is being fully torn down. After this, the plugin must
  /// not be used again.
  Future<void> dispose() async {
    final methodName = 'dispose';
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await _incomingCallsController.close();
    disposeCall();
    _logger.info('Plugin disposed', name: methodName);
  }

  /// Leaves the currently active outgoing call, if any.
  ///
  /// Used from app lifecycle callbacks (e.g. [AppLifecycleState.detached]) to
  /// ensure the LiveKit room and MatrixRTC session are released when the app
  /// exits. Safe to call when no call is active.
  Future<void> leaveCurrentCall() async {
    const methodName = 'leaveCurrentCall';
    final otherPartyChannelDid = _activeOtherPartyChannelDid;
    if (otherPartyChannelDid == null || _container == null) return;
    _logger.info(
      'Leaving current call for ${otherPartyChannelDid.topAndTail()}',
      name: methodName,
    );
    await leaveCall(otherPartyChannelDid);
  }

  // ---------------------------------------------------------------------------
  // Call state stream
  // ---------------------------------------------------------------------------

  /// Returns a broadcast stream of [AudioVideoCallServiceState] for
  /// [otherPartyChannelDid].
  ///
  /// The stream emits immediately with the current state and continues to emit
  /// on every change. The caller is responsible for cancelling the
  /// subscription.
  ///
  /// Requires `initialize` to have been called first.
  Stream<AudioVideoCallServiceState> callState(String otherPartyChannelDid) {
    final container = _requireContainer();
    final controller = StreamController<AudioVideoCallServiceState>.broadcast();
    final sub = container.listen(
      audioVideoCallServiceProvider(otherPartyChannelDid),
      (prev, next) {
        if (!controller.isClosed) controller.add(next);
      },
      fireImmediately: true,
    );
    const methodName = 'callState';
    _logger.info(
      'Call state stream opened for ${otherPartyChannelDid.topAndTail()}',
      name: methodName,
    );
    controller.onCancel = () {
      sub.close();
      controller.close();
      _logger.info(
        'Call state stream closed for ${otherPartyChannelDid.topAndTail()}',
        name: methodName,
      );
    };
    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Imperative call methods
  // ---------------------------------------------------------------------------

  /// Joins the LiveKit room for [otherPartyChannelDid].
  Future<void> joinCall(String otherPartyChannelDid) {
    _logger.info(
      'Joining call for ${otherPartyChannelDid.topAndTail()}',
      name: 'joinCall',
    );
    _activeOtherPartyChannelDid = otherPartyChannelDid;
    return _requireContainer()
        .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
        .joinCall();
  }

  /// Leaves the current call gracefully.
  Future<void> leaveCall(String otherPartyChannelDid) {
    _logger.info(
      'Leaving call for ${otherPartyChannelDid.topAndTail()}',
      name: 'leaveCall',
    );
    _activeOtherPartyChannelDid = null;
    return _requireContainer()
        .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
        .leaveCall();
  }

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(String otherPartyChannelDid, bool enabled) {
    _logger.info('Microphone enabled: $enabled', name: 'setMicrophoneEnabled');
    return _requireContainer()
        .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
        .setMicrophoneEnabled(enabled);
  }

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(String otherPartyChannelDid, bool enabled) {
    _logger.info('Camera enabled: $enabled', name: 'setCameraEnabled');
    return _requireContainer()
        .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
        .setCameraEnabled(enabled);
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece.
  Future<void> setSpeakerphoneEnabled(
    String otherPartyChannelDid,
    bool enabled,
  ) {
    _logger.info(
      'Speakerphone enabled: $enabled',
      name: 'setSpeakerphoneEnabled',
    );
    return _requireContainer()
        .read(audioVideoCallServiceProvider(otherPartyChannelDid).notifier)
        .setSpeakerphoneEnabled(enabled);
  }

  // ---------------------------------------------------------------------------
  // Widget scope (for video view)
  // ---------------------------------------------------------------------------

  /// Wraps [child] in a Riverpod ProviderScope backed by the plugin container.
  ///
  /// The call screen must be a descendant of this scope to use
  /// [MeetingPlaceLiveKitVideoView]. Requires [initialize] to have been called.
  Widget scope({required Widget child}) {
    final container = _requireContainer();
    return PluginScope(container: container, child: child);
  }

  /// Builds the video view for the participant [identity] in the call for
  /// [otherPartyChannelDid].
  ///
  /// The view is wrapped in the plugin container scope so it resolves the same
  /// `LiveKitService` instance the call is driving. Returns an empty box when
  /// the participant has no active video track. Pass `mirror: true` for the
  /// local camera preview.
  Widget videoView({
    required String otherPartyChannelDid,
    required String identity,
    bool mirror = false,
  }) {
    return scope(
      child: MeetingPlaceLiveKitVideoView(
        otherPartyChannelDid: otherPartyChannelDid,
        identity: identity,
        mirror: mirror,
      ),
    );
  }

  /// Stores [event] in the pending-call map and emits it on [incomingCalls].
  ///
  /// If a call is already ringing or active ([_activeCallId] is set), the
  /// invite is silently rejected (busy) and never emitted.
  void _emitIncomingCall(IncomingCallEvent event) {
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

  /// Handles an [IncomingCallSignal] from the SDK.
  ///
  /// Rings the device immediately from the nudge: a `call-invite`
  /// `ChannelActivity` is only ever sent after the caller has connected to
  /// LiveKit, so its arrival already means a live call exists. The caller's
  /// channel DID is the only value the banner needs; all Matrix and LiveKit
  /// resolution is deferred to [joinCall] on accept, where a brief
  /// "connecting" state covers the network latency. Drops duplicate signals
  /// (busy guard in [_emitIncomingCall]) and malformed channels silently.
  Future<void> _onIncomingCallSignal(IncomingCallSignal signal) async {
    const methodName = '_onIncomingCallSignal';
    final sdk = _sdk;
    if (sdk == null) return;

    _logger.info(
      'Incoming call signal received for ${signal.ownChannelDid.topAndTail()}',
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
        IncomingCallEvent(
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

  @override
  Future<void> startCall({required String contactId}) async {
    // TODO: signal AudioVideoCallService to initiate call setup.
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
    // _activeCallId stays set: the call transitions from ringing to active.
    // The app navigates to AudioVideoCallScreen(contactId) which calls
    // joinCall.
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

  @override
  Future<void> endCall({required String callId}) async {
    _logger.info('Call $callId ended', name: 'endCall');
    if (_activeCallId == callId) _activeCallId = null;
  }

  /// Called by the call service when the call session ends (hang-up,
  /// network drop, or remote party leaving). Clears the busy guard so new
  /// incoming calls can be received.
  void onCallEnded(String callId) {
    if (_activeCallId == callId) _activeCallId = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ProviderContainer _requireContainer() {
    final c = _container;
    if (c == null) {
      throw const MeetingPlaceLiveKitCallMisconfiguredException(
        'MeetingPlaceLiveKitCallPlugin.initialize() must be called before '
        'using call state or imperative methods.',
      );
    }
    return c;
  }
}
