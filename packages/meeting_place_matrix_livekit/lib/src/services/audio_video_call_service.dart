import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show
        AudioVideoCallErrorCode,
        AudioVideoCallParticipant,
        AudioVideoCallState,
        AudioVideoCallStatus,
        CallMediaType,
        CallRole;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/audio_video_call_defaults.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';
import '../interfaces/livekit_room.dart';
import '../models/call_e2ee_state.dart';
import '../providers/livekit_room_provider.dart';
import '../providers/plugin_core_sdk_provider.dart';
import '../providers/plugin_logger_provider.dart';
import '../providers/plugin_options_provider.dart';
import '../providers/plugin_rtc_delegate_provider.dart';
import '../providers/sfu_token_service_provider.dart';
import '../transport/call_invite_room_event.dart';
import '../utils/string.dart';
import 'sfu_token_service.dart';

part 'audio_video_call_service.g.dart';

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by the other party's permanent channel DID.
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns LivekitService and SfuTokenService for this call.
/// - Publishes the call state for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by the app's call screen controller via provider listeners.
/// Modelled after ChatSessionService.
@Riverpod(
  dependencies: [
    pluginCoreSdk,
    pluginOptions,
    pluginRtcDelegate,
    pluginLogger,
    sfuTokenService,
    livekitRoom,
  ],
)
class AudioVideoCallService extends _$AudioVideoCallService {
  static const _logKey = 'AudioVideoCallService';

  late final MeetingPlaceCoreSDKLogger _logger = ref.read(pluginLoggerProvider);
  late MeetingPlaceCoreSDK _sdk;
  late Duration _e2eeReadyTimeout;
  late Duration _outgoingCallTimeout;
  late SfuTokenService _livekitTokenService;
  late LiveKitRoom _room;
  late matrix.WebRTCDelegate _rtcDelegate;
  bool _isDisposed = false;
  bool _isTearingDown = false;
  Timer? _e2eeReadyTimer;
  Timer? _outgoingCallTimer;
  String? _matrixRoomId;
  String? _matrixCallId;

  /// Number of times a recipient retries discovering the in-progress call's
  /// callId before giving up, to absorb state-sync lag behind the call-invite.
  static const _recipientCallIdDiscoveryAttempts = 5;

  /// Delay between recipient callId-discovery attempts.
  static const _recipientCallIdDiscoveryInterval = Duration(milliseconds: 300);

  /// Participants whose media currently reports a missing decryption key.
  ///
  /// Populated from [_onE2EEStateChanged] and used only to drive the
  /// waitingForKeys -> active state transition. We deliberately do NOT send
  /// explicit `encryption_keys_request` events: matrix performs its own
  /// membership-driven key exchange on join, and an explicit request arriving
  /// after a membership re-sync makes the publisher's matrix layer lose its
  /// local key ("no keys found"), regenerate it, and churn index 0 with an
  /// inconsistent key, which strands the decoder on a black frame.
  final Set<String> _participantsMissingKey = {};

  /// Participants whose media has successfully decrypted at least once
  /// (reached [CallE2EEState.ok]).
  final Set<String> _participantsKeyed = {};

  /// Active keyframe-nudge timers keyed by participant id. A timer forces the
  /// SFU to resend a keyframe so a decoder stuck on a missing key recovers once
  /// matrix's native key exchange delivers the publisher key.
  final Map<String, Timer> _keyframeNudgeTimers = {};

  /// Number of keyframe nudges already issued per participant.
  final Map<String, int> _keyframeNudgeAttempts = {};

  /// Upper bound on keyframe nudges per participant before giving up.
  static const _maxKeyframeNudges = 5;

  /// Delay between keyframe nudges, giving matrix's to-device key exchange time
  /// to deliver and apply the publisher key before each retry.
  static const _keyframeNudgeInterval = Duration(seconds: 2);

  @override
  AudioVideoCallState build(String otherPartyChannelDid) {
    _sdk = ref.read(pluginCoreSdkProvider);
    _e2eeReadyTimeout = ref.read(pluginOptionsProvider).e2eeReadyTimeout;
    _outgoingCallTimeout = ref.read(pluginOptionsProvider).outgoingCallTimeout;
    _rtcDelegate = ref.read(pluginRtcDelegateProvider);
    _livekitTokenService = ref.read(sfuTokenServiceProvider);
    _room = ref.watch(livekitRoomProvider(otherPartyChannelDid));

    ref.onDispose(() {
      _isDisposed = true;
      _e2eeReadyTimer?.cancel();
      _outgoingCallTimer?.cancel();
      _cancelKeyframeNudges();
      final roomId = _matrixRoomId;
      final callId = _matrixCallId;
      if (roomId != null && callId != null) {
        unawaited(_sdk.leaveVideoCall(roomId: roomId, callId: callId));
      }
      // Ensure the LiveKit room is always released, even if leaveCall() was
      // never called (e.g. screen popped mid-call or app killed).
      unawaited(_room.disconnect());
    });

    return AudioVideoCallState.initial;
  }

  Future<void> joinCall({
    bool isRecipient = false,
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    if (_isDisposed) {
      _logger.info('joinCall: Skipping, service disposed', name: _logKey);
      return;
    }
    // Reset per-call key tracking so a fresh call generation (e.g. call again
    // on the same service instance) does not inherit stale keyed/missing state.
    _participantsKeyed.clear();
    _participantsMissingKey.clear();
    _cancelKeyframeNudges();
    state = state.copyWith(
      status: AudioVideoCallStatus.connecting,
      clearErrorCode: true,
    );

    var errorCode = AudioVideoCallErrorCode.unexpected;
    var succeeded = false;
    try {
      errorCode = AudioVideoCallErrorCode.channelNotFound;
      final (:channel, :ownChannelDid, :roomName) = await _resolveChannel();

      errorCode = AudioVideoCallErrorCode.tokenFetchFailed;
      final (
        :didManager,
        :matrixRoomId,
        :sfuUrl,
        :sfuToken,
        :participantIdToDid,
      ) = await _fetchCallCredentials(
        channel: channel,
        ownChannelDid: ownChannelDid,
        roomName: roomName,
      );

      errorCode = AudioVideoCallErrorCode.connectionFailed;
      final (:callAlreadyInProgress, :callId) = await _prepareCallSession(
        didManager: didManager,
        matrixRoomId: matrixRoomId,
        isRecipient: isRecipient,
      );

      if (!isRecipient) {
        errorCode = AudioVideoCallErrorCode.callInviteFailed;
        await _sendCallInvite(
          channel: channel,
          callAlreadyInProgress: callAlreadyInProgress,
          mediaType: mediaType,
        );
      }

      errorCode = AudioVideoCallErrorCode.connectionFailed;
      await _connectLiveKitRoom(
        sfuUrl: sfuUrl,
        sfuToken: sfuToken,
        participantIdToDid: participantIdToDid,
      );

      final isJoiningExistingCall = isRecipient || callAlreadyInProgress;
      // Emit the device's role early so the call chat item appears immediately.
      state = state.copyWith(
        ownRole: isJoiningExistingCall ? CallRole.recipient : CallRole.caller,
      );

      await _enableLocalMedia(mediaType: mediaType);
      await _registerMatrixCall(
        didManager: didManager,
        matrixRoomId: matrixRoomId,
        callId: callId,
        sfuUrl: sfuUrl,
        roomName: roomName,
      );

      if (_isDisposed) {
        _logger.info(
          'joinCall: Skipping post-connect state, service disposed',
          name: _logKey,
        );
        return;
      }

      final ownRole = isJoiningExistingCall
          ? CallRole.recipient
          : CallRole.caller;
      final hasPeer = _hasPeer;
      if (ownRole == CallRole.caller && !hasPeer) {
        _logger.info(
          'joinCall: Caller alone in room, starting outgoing ring timer '
          '(${_outgoingCallTimeout.inSeconds}s)',
          name: _logKey,
        );
        state = state.copyWith(
          status: AudioVideoCallStatus.outgoingRinging,
          participants: _room.participants,
          ownRole: ownRole,
        );
        _outgoingCallTimer = Timer(
          _outgoingCallTimeout,
          _onOutgoingCallTimeout,
        );
      } else {
        state = state.copyWith(
          status: AudioVideoCallStatus.waitingForKeys,
          participants: _room.participants,
          ownRole: ownRole,
        );
        _e2eeReadyTimer = Timer(_e2eeReadyTimeout, _onE2EETimeout);
      }
      succeeded = true;
    } on MeetingPlaceLiveKitCallOperationException catch (e, stackTrace) {
      if (_isDisposed || _isTearingDown) {
        _logger.info(
          'joinCall: Swallowing operation error, call torn down',
          name: _logKey,
        );
        return;
      }
      _logger.error(
        'Failed to join call',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      state = state.copyWith(
        status: AudioVideoCallStatus.error,
        errorCode: errorCode,
      );
    } catch (e, stackTrace) {
      if (_isDisposed || _isTearingDown) {
        _logger.info(
          'joinCall: Swallowing unexpected error, call torn down',
          name: _logKey,
        );
        return;
      }
      _logger.error(
        'Unexpected error joining call',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      state = state.copyWith(
        status: AudioVideoCallStatus.error,
        errorCode: AudioVideoCallErrorCode.unexpected,
      );
    } finally {
      // If the call setup did not complete successfully, stop the LiveKit room
      // immediately. Without this, a Room that threw during connect() keeps its
      // internal reconnect loop running until the provider is disposed.
      if (!succeeded) unawaited(_room.disconnect());
    }
  }

  /// Resolves the channel for [otherPartyChannelDid] and derives the LiveKit
  /// room name.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when the channel or its
  /// permanentChannelDid cannot be resolved.
  Future<({Channel channel, String ownChannelDid, String roomName})>
  _resolveChannel() async {
    final channel = await _sdk.getChannelByOtherPartyPermanentDid(
      otherPartyChannelDid,
    );
    if (channel == null) {
      throw MeetingPlaceLiveKitCallOperationException(
        'No channel found for contact DID: $otherPartyChannelDid',
      );
    }
    final ownChannelDid = channel.permanentChannelDid;
    if (ownChannelDid == null) {
      throw MeetingPlaceLiveKitCallOperationException(
        'Channel for contact $otherPartyChannelDid'
        ' has no permanentChannelDid',
      );
    }
    final roomName = channel.isGroup
        ? _sdk.livekitRoomName(channelDid: otherPartyChannelDid)
        : _sdk.livekitRoomName(
            channelDid: ownChannelDid,
            otherPartyChannelDid: otherPartyChannelDid,
          );
    return (channel: channel, ownChannelDid: ownChannelDid, roomName: roomName);
  }

  /// Fetches all credentials needed to join the LiveKit room: the DID manager,
  /// Matrix room id, OpenID token, device id, participant-id-to-DID map, SFU
  /// JWT, and the resolved SFU URL.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no SFU URL is
  /// available.
  Future<
    ({
      DidManager didManager,
      String matrixRoomId,
      String sfuUrl,
      String sfuToken,
      Map<String, String> participantIdToDid,
    })
  >
  _fetchCallCredentials({
    required Channel channel,
    required String ownChannelDid,
    required String roomName,
  }) async {
    final didManager = await _sdk.getDidManager(ownChannelDid);
    final matrixRoomId = await _sdk.resolveMatrixRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    final openIdToken = await _sdk.getMatrixOpenIdToken(didManager);
    final deviceId = await _sdk.getMatrixDeviceId(didManager);
    final participantIdToDid = await _buildParticipantIdToDidMap(
      channel: channel,
      ownChannelDid: ownChannelDid,
      serverName: openIdToken.matrixServerName,
    );
    final tokenResponse = await _livekitTokenService.fetchToken(
      roomName: roomName,
      openIdCredentials: openIdToken,
      deviceId: deviceId,
    );
    final sfuUrl =
        ref.read(pluginOptionsProvider).livekitSfuUrl?.toString() ??
        tokenResponse.url;
    if (sfuUrl == null) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'No LiveKit SFU URL available: set livekitSfuUrl in plugin options '
        'or ensure lk-jwt-service returns a URL in the response',
      );
    }
    return (
      didManager: didManager,
      matrixRoomId: matrixRoomId,
      sfuUrl: sfuUrl,
      sfuToken: tokenResponse.token,
      participantIdToDid: participantIdToDid,
    );
  }

  /// Initialises MatrixRTC, checks for an in-progress call, and creates the
  /// E2EE key provider.
  ///
  /// This is the cheap preparation phase that must complete before the
  /// call-invite nudge is sent, so the rejoin decision is known. It does not
  /// connect the LiveKit room: see [_connectLiveKitRoom].
  ///
  /// Returns whether a call was already in progress in the room before this
  /// device joined (rejoin scenario), and the callId to register against.
  Future<({bool callAlreadyInProgress, String callId})> _prepareCallSession({
    required DidManager didManager,
    required String matrixRoomId,
    required bool isRecipient,
  }) async {
    await _sdk.initializeMatrixRTCWithDelegate(
      didManager: didManager,
      delegate: _rtcDelegate,
    );

    final existingCallId = await _resolveExistingCallId(
      didManager: didManager,
      roomId: matrixRoomId,
      isRecipient: isRecipient,
    );
    final callAlreadyInProgress = existingCallId != null;
    final callId =
        existingCallId ??
        '$matrixRoomId@${DateTime.now().microsecondsSinceEpoch}';
    _logger.info(
      'Active call membership check: '
      'callAlreadyInProgress=$callAlreadyInProgress callId=$callId'
      ' for room $matrixRoomId',
      name: _logKey,
    );

    await _room.setSharedKey('mpx-call-shared-key:$matrixRoomId');

    return (callAlreadyInProgress: callAlreadyInProgress, callId: callId);
  }

  /// Connects the LiveKit room. This is the heavy phase (SFU handshake and
  /// E2EE negotiation) and runs after the call-invite nudge has been sent.
  Future<void> _connectLiveKitRoom({
    required String sfuUrl,
    required String sfuToken,
    required Map<String, String> participantIdToDid,
  }) async {
    await _room.connect(
      url: sfuUrl,
      token: sfuToken,
      participantIdToDid: participantIdToDid,
      onE2EEStateChanged: _onE2EEStateChanged,
      onParticipantDisconnected: _onParticipantDisconnected,
      onParticipantsChanged: _onParticipantsChanged,
    );
  }

  /// Resolves the callId of the in-progress call in [roomId], or `null` when
  /// no call is active.
  ///
  /// A recipient is answering a call the caller already published, so its
  /// membership must be discoverable. Because state sync can lag behind the
  /// call-invite signal, the recipient retries briefly before giving up; the
  /// caller does not, since it is the one creating the call.
  Future<String?> _resolveExistingCallId({
    required DidManager didManager,
    required String roomId,
    required bool isRecipient,
  }) async {
    final attempts = isRecipient ? _recipientCallIdDiscoveryAttempts : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final callId = await _sdk.activeVideoCallId(
        didManager: didManager,
        roomId: roomId,
      );
      if (callId != null) return callId;
      if (attempt < attempts - 1) {
        await Future<void>.delayed(_recipientCallIdDiscoveryInterval);
      }
    }
    return null;
  }

  /// Signals the Matrix homeserver that a video call has started and stores the
  /// room/call identifiers for cleanup in [leaveCall] and ref.onDispose.
  Future<void> _registerMatrixCall({
    required DidManager didManager,
    required String matrixRoomId,
    required String callId,
    required String sfuUrl,
    required String roomName,
  }) async {
    await _sdk.startVideoCall(
      didManager: didManager,
      roomId: matrixRoomId,
      callId: callId,
      livekitServiceUrl: sfuUrl,
      livekitAlias: roomName,
    );
    _matrixRoomId = matrixRoomId;
    _matrixCallId = callId;
  }

  /// Sends a call-invite nudge to [channel] via the control-plane pipeline.
  ///
  /// No-ops silently when [callAlreadyInProgress] is true: this is a rejoin
  /// (e.g. after an app restart) and a duplicate invite must not be sent.
  Future<void> _sendCallInvite({
    required Channel channel,
    required bool callAlreadyInProgress,
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    if (callAlreadyInProgress) {
      _logger.warning(
        'Skipping call-invite nudge to '
        '${otherPartyChannelDid.topAndTail()}: rejoining in-progress call',
        name: _logKey,
      );
      return;
    }
    if (channel.isGroup) {
      await _sdk.sendChannelNotification(
        GroupChannelNotification(
          offerLink: channel.offerLink,
          groupDid: otherPartyChannelDid,
          type: ChannelActivityType.callInvite,
        ),
      );
    } else {
      await _sdk.sendMessage(
        CallInviteRoomEvent(
          senderDid: channel.permanentChannelDid!,
          mediaType: mediaType,
          recipientDid: otherPartyChannelDid,
        ),
      );
    }
    _logger.info(
      'Sent call-invite nudge to ${otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  /// Leaves the LiveKit room gracefully.
  Future<void> leaveCall() async {
    if (_isDisposed) {
      _logger.info('leaveCall: Skipping, service disposed', name: _logKey);
      return;
    }
    _isTearingDown = true;

    const preAnswerStatuses = {
      AudioVideoCallStatus.connecting,
      AudioVideoCallStatus.outgoingRinging,
    };
    final cancelledBeforeAnswer =
        state.ownRole == CallRole.caller &&
        !_hasPeer &&
        preAnswerStatuses.contains(state.status);
    state = state.copyWith(status: AudioVideoCallStatus.disconnecting);
    _e2eeReadyTimer?.cancel();
    _outgoingCallTimer?.cancel();
    _cancelKeyframeNudges();

    if (cancelledBeforeAnswer) _sendCallCancelToRecipient();

    // Null out before awaiting so onDispose does not repeat the cleanup if
    // the screen is dismissed while this method is in flight.
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;

    try {
      if (roomId != null && callId != null) {
        await _sdk.leaveVideoCall(roomId: roomId, callId: callId);
      }
      await _room.disconnect();
    } catch (e, stackTrace) {
      _logger.warning(
        'leaveCall: Ignoring teardown error during call cancellation: $e\n'
        '$stackTrace',
        name: _logKey,
      );
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(
          status: AudioVideoCallStatus.disconnected,
          participants: <AudioVideoCallParticipant>[],
        );
      }
    }
  }

  /// Enables or disables the local microphone.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setMicrophoneEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setMicrophoneEnabled(enabled);
    state = state.copyWith(participants: _room.participants);
  }

  /// Enables or disables the local camera.
  Future<void> setCameraEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setCameraEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setCameraEnabled(enabled);
    state = state.copyWith(participants: _room.participants);
  }

  /// Switches between front and rear camera.
  Future<void> switchCamera() async {
    if (_isDisposed) return;
    await _room.switchCamera();
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece
  /// ([enabled] = false).
  ///
  /// The presentation layer determines the initial value based on contact type
  /// and call mode, then calls this method on each user toggle. No-op when
  /// disposed.
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (_isDisposed) {
      _logger.info(
        'setSpeakerphoneEnabled: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    await _room.setSpeakerphoneEnabled(enabled);
  }

  /// Builds a map from each expected participant id (the LiveKit identity, a
  /// Matrix user id) to the participant's permanent channel DID.
  ///
  /// The Matrix user id is a deterministic hash of the DID and server name,
  /// so reversing it just means deriving the id for every known DID. For a
  /// group the candidate DIDs are the group members; for a 1:1 call they are
  /// the local user and the other party. The LiveKit service consumes this to
  /// stamp a DID on each domain participant.
  Future<Map<String, String>> _buildParticipantIdToDidMap({
    required Channel channel,
    required String ownChannelDid,
    required String serverName,
  }) async {
    final dids = <String>{ownChannelDid};
    if (channel.isGroup) {
      final group = await _sdk.getGroupByOfferLink(channel.offerLink);
      if (group != null) {
        dids.addAll(group.members.map((member) => member.did));
      }
    } else {
      dids.add(otherPartyChannelDid);
    }
    return {for (final did in dids) deriveMatrixUserId(did, serverName): did};
  }

  /// Publishes the local microphone and camera tracks after connecting.
  ///
  /// Camera failures are logged but not fatal: device emulators and machines
  /// without a camera throw here, yet the call must still proceed audio-only.
  Future<void> _enableLocalMedia({
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    try {
      await _room.setMicrophoneEnabled(true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to enable microphone',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
    if (mediaType == CallMediaType.audio) return;
    try {
      await _room.setCameraEnabled(true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to enable camera',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }

  void _onParticipantsChanged() {
    if (_isDisposed) {
      _logger.info(
        '_onParticipantsChanged: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }

    if (state.status == AudioVideoCallStatus.outgoingRinging && _hasPeer) {
      _logger.info(
        '_onParticipantsChanged: Other participant joined, '
        'outgoingRinging -> waitingForKeys',
        name: _logKey,
      );
      _outgoingCallTimer?.cancel();
      _outgoingCallTimer = null;
      state = state.copyWith(
        status: AudioVideoCallStatus.waitingForKeys,
        participants: _room.participants,
      );
      _e2eeReadyTimer ??= Timer(_e2eeReadyTimeout, _onE2EETimeout);
      return;
    }
    state = state.copyWith(participants: _room.participants);
  }

  /// Whether any participant other than this device is currently in the room.
  bool get _hasPeer => _room.participants.any((p) => !p.isSelf);

  /// Sends a `call-decline` nudge to the other party so a caller hanging up or
  /// timing out before the call is answered immediately dismisses the
  /// recipient's ringing UI and marks their chat item missed. Mirrors the
  /// call-invite nudge sent in [joinCall]; individual calls only.
  void _sendCallCancelToRecipient() {
    _logger.info(
      'Sending call-cancel nudge to ${otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    unawaited(
      _sdk.sendChannelNotification(
        IndividualChannelNotification(
          recipientDid: otherPartyChannelDid,
          type: ChannelActivityType.callDecline,
        ),
      ),
    );
  }

  void _onParticipantDisconnected(String participantId) {
    if (_isDisposed) {
      _logger.info(
        '_onParticipantDisconnected: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }

    // Ratchet own key so the departed participant cannot decrypt future media.
    // Only valid with per-participant keys: ratcheting a shared key on one side
    // would desync the room.
    if (!AudioVideoCallDefaults.sharedKeyEncryption) {
      final ownParticipantId = _room.ownParticipantId;
      if (ownParticipantId != null) {
        unawaited(_room.ratchetKey(ownParticipantId, 0));
      }
    }
    state = state.copyWith(participants: _room.participants);
  }

  void _onE2EEStateChanged(String participantId, CallE2EEState e2eeState) {
    if (_isDisposed) {
      _logger.info(
        '_onE2EEStateChanged: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    _logger.info(
      '_onE2EEStateChanged: participant=$participantId state=$e2eeState',
      name: _logKey,
    );
    if (e2eeState == CallE2EEState.ok) {
      _participantsKeyed.add(participantId);
      _participantsMissingKey.remove(participantId);
      _cancelKeyframeNudge(participantId);
      _e2eeReadyTimer?.cancel();
      if (state.status == AudioVideoCallStatus.waitingForKeys ||
          state.status == AudioVideoCallStatus.connected) {
        state = state.copyWith(
          status: AudioVideoCallStatus.active,
          participants: _room.participants,
        );
      }
    } else if (e2eeState == CallE2EEState.missingKey) {
      _participantsMissingKey.add(participantId);
      _scheduleKeyframeNudge(participantId);
    }
  }

  /// Starts a bounded periodic keyframe nudge for [participantId] until its
  /// media decrypts ([CallE2EEState.ok]) or the attempt budget is exhausted.
  void _scheduleKeyframeNudge(String participantId) {
    if (_keyframeNudgeTimers.containsKey(participantId)) return;
    _logger.info(
      '_scheduleKeyframeNudge: starting for $participantId',
      name: _logKey,
    );
    _keyframeNudgeAttempts[participantId] = 0;
    _keyframeNudgeTimers[participantId] = Timer.periodic(
      _keyframeNudgeInterval,
      (timer) {
        if (_isDisposed ||
            _participantsKeyed.contains(participantId) ||
            !_participantsMissingKey.contains(participantId)) {
          _cancelKeyframeNudge(participantId);
          return;
        }
        final attempts = (_keyframeNudgeAttempts[participantId] ?? 0) + 1;
        _keyframeNudgeAttempts[participantId] = attempts;
        if (attempts > _maxKeyframeNudges) {
          _logger.warning(
            '_scheduleKeyframeNudge: giving up on $participantId after '
            '$_maxKeyframeNudges attempts',
            name: _logKey,
          );
          _cancelKeyframeNudge(participantId);
          return;
        }
        _logger.info(
          '_scheduleKeyframeNudge: nudge $attempts for $participantId',
          name: _logKey,
        );
        unawaited(_room.forceRemoteKeyframe(participantId));
      },
    );
  }

  /// Cancels the keyframe nudge timer for a single [participantId].
  void _cancelKeyframeNudge(String participantId) {
    _keyframeNudgeTimers.remove(participantId)?.cancel();
    _keyframeNudgeAttempts.remove(participantId);
  }

  /// Cancels all in-flight keyframe nudge timers.
  void _cancelKeyframeNudges() {
    for (final timer in _keyframeNudgeTimers.values) {
      timer.cancel();
    }
    _keyframeNudgeTimers.clear();
    _keyframeNudgeAttempts.clear();
  }

  void _onOutgoingCallTimeout() {
    if (_isDisposed) {
      _logger.info(
        '_onOutgoingCallTimeout: Skipping, service disposed',
        name: _logKey,
      );
      return;
    }
    if (state.status != AudioVideoCallStatus.outgoingRinging) return;
    _logger.info(
      '_onOutgoingCallTimeout: No answer after '
      '${_outgoingCallTimeout.inSeconds}s, '
      'leaving room and emitting missed',
      name: _logKey,
    );
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;
    if (roomId != null && callId != null) {
      unawaited(_sdk.leaveVideoCall(roomId: roomId, callId: callId));
    }
    unawaited(_room.disconnect());
    _sendCallCancelToRecipient();
    state = state.copyWith(
      status: AudioVideoCallStatus.missed,
      participants: <AudioVideoCallParticipant>[],
    );
  }

  /// Called by the plugin when a `call-decline` signal arrives from the callee.
  ///
  /// No-ops silently if the service is disposed or not in
  ///  [AudioVideoCallStatus.outgoingRinging].
  void notifyDeclined() {
    if (_isDisposed) {
      _logger.info('notifyDeclined: Skipping, service disposed', name: _logKey);
      return;
    }
    if (state.status != AudioVideoCallStatus.outgoingRinging) return;
    _logger.info(
      'notifyDeclined: Callee declined, leaving room and emitting declined',
      name: _logKey,
    );
    _outgoingCallTimer?.cancel();
    _outgoingCallTimer = null;
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;
    if (roomId != null && callId != null) {
      unawaited(_sdk.leaveVideoCall(roomId: roomId, callId: callId));
    }
    unawaited(_room.disconnect());
    state = state.copyWith(
      status: AudioVideoCallStatus.declined,
      participants: <AudioVideoCallParticipant>[],
    );
  }

  void _onE2EETimeout() {
    if (_isDisposed) {
      _logger.info('_onE2EETimeout: Skipping, service disposed', name: _logKey);
      return;
    }
    if (state.status == AudioVideoCallStatus.waitingForKeys) {
      // Transition to connected anyway — the call is usable even if E2EE
      // keys for some remote participants haven't arrived yet.
      state = state.copyWith(
        status: AudioVideoCallStatus.connected,
        participants: _room.participants,
      );
    }
  }
}
