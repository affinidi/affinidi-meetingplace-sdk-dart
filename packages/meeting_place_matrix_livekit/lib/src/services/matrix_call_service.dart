import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';

/// Owns the MatrixRTC call lifecycle for the livekit package.
///
/// This service is stateful: it holds the [matrix.VoIP] instance and manages
/// the incoming-call activation queue. Construct once per user session and
/// dispose when the session ends.
class MatrixCallService {
  MatrixCallService({
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _matrixService = matrixService,
       _logger =
           logger ??
           DefaultMeetingPlaceCoreSDKLogger(className: 'MatrixCallService');

  final MatrixService _matrixService;
  final MeetingPlaceCoreSDKLogger _logger;

  static const _logKey = 'MatrixCallService';

  /// VoIP instance for MatrixRTC call management. Set via [initializeVoIP]
  /// or [initializeVoIPWithDelegate] before calling [startCall].
  matrix.VoIP? _voip;

  /// The VoIP instance whose [matrix.VoIP.onIncomingGroupCall] stream is
  /// currently subscribed.
  ///
  /// That stream is single-subscription, so the service listens to it exactly
  /// once per VoIP instance (see [_ensureIncomingGroupCallListener]) rather
  /// than re-listening on every [activateIncomingCall] call.
  matrix.VoIP? _incomingCallListenerVoip;

  /// Subscription to [matrix.VoIP.onIncomingGroupCall] for the VoIP instance
  /// referenced by [_incomingCallListenerVoip].
  StreamSubscription<matrix.GroupCallSession>? _incomingGroupCallSubscription;

  /// In-flight [activateIncomingCall] requests waiting for their group call to
  /// surface in room state.
  final List<({String roomId, Completer<matrix.GroupCallSession> completer})>
  _pendingActivations = [];

  // ---------------------------------------------------------------------------
  // VoIP initialization
  // ---------------------------------------------------------------------------

  /// Injects the [matrix.VoIP] instance required for MatrixRTC call management.
  void initializeVoIP(matrix.VoIP voip) {
    _voip = voip;
  }

  /// Creates a [matrix.VoIP] instance from [delegate] and an authenticated
  /// client for [didManager], then stores it for call operations.
  Future<void> initializeVoIPWithDelegate({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
  }) async {
    final client = await _matrixService.authenticatedClient(didManager);
    _voip = matrix.VoIP(client, delegate);
  }

  // ---------------------------------------------------------------------------
  // Incoming call activation
  // ---------------------------------------------------------------------------

  /// Lazily activates the single Matrix session for [didManager] and resolves
  /// the pending incoming MatrixRTC group call published in [roomId].
  ///
  /// This is the on-demand counterpart to [startCall]. Instead of holding a
  /// background sync at rest, the caller invokes this only after an
  /// out-of-band signal (a call push or mediator message) reports an incoming
  /// call for a specific channel. It logs in that one DID's Matrix session,
  /// initialises VoIP with [delegate] when needed, and returns the
  /// [matrix.GroupCallSession] the remote party created in [roomId].
  ///
  /// The membership is usually already present in room state, in which case
  /// this returns immediately. Otherwise it waits for the next sync to deliver
  /// it, up to [timeout].
  ///
  /// Throws [MatrixServiceException.incomingCallNotFound] if no group call
  /// surfaces within [timeout].
  Future<matrix.GroupCallSession> activateIncomingCall({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
    required String roomId,
    Duration timeout = MatrixRtcDefaults.incomingCallActivationTimeout,
  }) async {
    _logger.info('Activating incoming call for room $roomId', name: _logKey);

    final client = await _matrixService.authenticatedClient(didManager);
    final voip = _voip ??= matrix.VoIP(client, delegate);

    final existing = _findGroupCallForRoom(voip, roomId);
    if (existing != null) {
      _logger.info(
        'Found existing group call ${existing.groupCallId} in room $roomId',
        name: _logKey,
      );
      return existing;
    }

    final completer = Completer<matrix.GroupCallSession>();
    final activation = (roomId: roomId, completer: completer);
    _pendingActivations.add(activation);

    // Subscribe once per VoIP instance to its single-subscription
    // onIncomingGroupCall stream so memberships that arrive in a later sync
    // resolve the activation.
    _ensureIncomingGroupCallListener(voip);

    // Drive VoIP discovery eagerly: a freshly authenticated session resolves
    // the room only via its alias directory and has not synced the room, so
    // the caller's m.call.member state event is not yet visible to the VoIP
    // constructor backfill. Loading the room and replaying its call
    // memberships covers that gap without depending on onRoomState firing for
    // state that predates the VoIP instance.
    unawaited(_discoverExistingGroupCall(voip, client, roomId));

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _logger.warning(
        'No incoming call surfaced in room $roomId within '
        '${timeout.inSeconds}s',
        name: _logKey,
      );
      throw MatrixServiceException.incomingCallNotFound(roomId);
    } finally {
      _pendingActivations.remove(activation);
    }
  }

  // ---------------------------------------------------------------------------
  // Call operations
  // ---------------------------------------------------------------------------

  /// Requests a Matrix OpenID token for [didManager].
  Future<matrix.OpenIdCredentials> getOpenIdToken(DidManager didManager) async {
    final client = await _matrixService.authenticatedClient(didManager);
    final userId = client.userID;
    if (userId == null) throw MatrixServiceException.missingUserId();
    return client.requestOpenIdToken(userId, {});
  }

  /// Returns the Matrix device ID for the active session of [didManager].
  Future<String?> getDeviceId(DidManager didManager) async {
    final client = await _matrixService.authenticatedClient(didManager);
    return client.deviceID;
  }

  /// Creates or joins a MatrixRTC group call in [roomId] using the LiveKit SFU.
  Future<matrix.GroupCallSession> startCall({
    required DidManager didManager,
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) async {
    final voip = _voip;
    if (voip == null) throw MatrixServiceException.voipNotInitialized();

    final client = await _matrixService.authenticatedClient(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) throw MatrixServiceException.roomNotFound(roomId);

    final backend = matrix.LiveKitBackend(
      livekitServiceUrl: livekitServiceUrl,
      livekitAlias: livekitAlias,
      e2eeEnabled: MatrixRtcDefaults.e2eeEnabled,
    );

    final session = await voip.fetchOrCreateGroupCall(
      callId ?? roomId,
      room,
      backend,
      MatrixRtcCallType.call.value,
      MatrixRtcCallScope.room.value,
      preShareKey: MatrixRtcDefaults.preShareKey,
    );

    if (session.state != matrix.GroupCallState.entered) {
      await session.enter();
    }
    return session;
  }

  /// Leaves the active MatrixRTC group call in [roomId] with [callId].
  Future<void> leaveCall({
    required String roomId,
    required String callId,
  }) async {
    final session = _voip?.getGroupCallById(roomId, callId);
    if (session == null) return;
    await session.leave();
  }

  /// Returns a stream of MatrixRTC call events for the given call, or `null`
  /// if VoIP is not initialized.
  Stream<matrix.MatrixRTCCallEvent>? watchCall({
    required String roomId,
    required String callId,
  }) => _voip?.getGroupCallById(roomId, callId)?.matrixRTCEventStream.stream;

  /// Returns `true` when [roomId] has an active (non-expired) MatrixRTC
  /// call membership.
  Future<bool> hasActiveCall({
    required DidManager didManager,
    required String roomId,
  }) async =>
      (await activeCallId(didManager: didManager, roomId: roomId)) != null;

  /// Returns the callId of the first non-expired MatrixRTC membership in
  /// [roomId], or `null` when no call is in progress.
  Future<String?> activeCallId({
    required DidManager didManager,
    required String roomId,
  }) async {
    final voip = _voip;
    if (voip == null) return null;

    final client = await _matrixService.authenticatedClient(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) return null;

    for (final memberships in room.getCallMembershipsFromRoom(voip).values) {
      for (final membership in memberships) {
        if (!membership.isExpired) return membership.callId;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Room resolution
  // ---------------------------------------------------------------------------

  /// Resolves the Matrix room ID for [channel].
  Future<String> resolveRoomIdForChannel({
    required DidManager didManager,
    required Channel channel,
  }) => _matrixService.resolveRoomIdForChannel(
    didManager: didManager,
    channel: channel,
  );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancels the incoming-call listener subscription. Call when the session
  /// ends.
  void dispose() {
    _incomingGroupCallSubscription?.cancel();
    _incomingGroupCallSubscription = null;
    _incomingCallListenerVoip = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Listens to [voip]'s single-subscription [matrix.VoIP.onIncomingGroupCall]
  /// stream exactly once, cancelling any subscription to a previous instance.
  ///
  /// onIncomingGroupCall fires synchronously inside
  /// `createGroupCallFromRoomStateEvent` right after `setGroupCallById`,
  /// covering both the VoIP constructor backfill and the onRoomState-from-sync
  /// path. Listening here once per instance avoids the "Stream has already
  /// been listened to" error that re-listening per call would cause on the
  /// cached VoIP instance.
  void _ensureIncomingGroupCallListener(matrix.VoIP voip) {
    if (identical(_incomingCallListenerVoip, voip)) return;
    _incomingGroupCallSubscription?.cancel();
    _incomingCallListenerVoip = voip;
    _incomingGroupCallSubscription = voip.onIncomingGroupCall.stream.listen(
      (_) => _resolvePendingActivations(voip),
    );
  }

  void _resolvePendingActivations(matrix.VoIP voip) {
    for (final activation in List.of(_pendingActivations)) {
      if (activation.completer.isCompleted) continue;
      final session = _findGroupCallForRoom(voip, activation.roomId);
      if (session != null) activation.completer.complete(session);
    }
  }

  /// Loads [roomId] when the session has not synced it yet, then replays every
  /// call membership already present in its state through
  /// [matrix.VoIP.createGroupCallFromRoomStateEvent], which is idempotent.
  ///
  /// This is the deterministic counterpart to the onIncomingGroupCall listener:
  /// the listener only covers memberships that arrive in a future sync, whereas
  /// the caller's m.call.member event is typically already in the room state by
  /// the time the callee activates. Best-effort by design; any failure leaves
  /// the activation to resolve via the listener or time out.
  Future<void> _discoverExistingGroupCall(
    matrix.VoIP voip,
    matrix.Client client,
    String roomId,
  ) async {
    try {
      if (client.getRoomById(roomId) == null) {
        await client.waitForRoomInSync(roomId, join: true);
      }
      final room = client.getRoomById(roomId);
      if (room == null) {
        _logger.warning(
          'Room $roomId did not load after sync; relying on '
          'onIncomingGroupCall for incoming call discovery',
          name: _logKey,
        );
        return;
      }
      for (final memberships in room.getCallMembershipsFromRoom(voip).values) {
        for (final membership in memberships) {
          await voip.createGroupCallFromRoomStateEvent(membership);
        }
      }
      _resolvePendingActivations(voip);
    } catch (e, stackTrace) {
      _logger.error(
        'Eager incoming call discovery failed for room $roomId',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }

  matrix.GroupCallSession? _findGroupCallForRoom(
    matrix.VoIP voip,
    String roomId,
  ) {
    for (final entry in voip.groupCalls.entries) {
      if (entry.key.roomId == roomId) return entry.value;
    }
    return null;
  }
}
