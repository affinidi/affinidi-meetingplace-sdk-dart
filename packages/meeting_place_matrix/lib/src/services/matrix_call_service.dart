import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../../meeting_place_matrix.dart';
import '../matrix_service_exception.dart';
import '../rtc/matrix_rtc_call_scope.dart';
import '../rtc/matrix_rtc_call_type.dart';
import '../rtc/matrix_rtc_defaults.dart';
import 'matrix_session_accessor.dart';

/// MatrixRTC / VoIP call lifecycle: VoIP initialisation, incoming-call
/// activation, call membership discovery, and group-call start/leave/watch.
///
/// Owns the VoIP instance and the incoming-group-call subscription so the
/// stream lifecycle lives in one place. Obtains authenticated clients through
/// [EnsureMatrixSession] rather than owning any session state. Constructed and
/// owned by `MatrixService`, which exposes these operations through its public
/// facade.
class MatrixCallService {
  MatrixCallService({
    required EnsureMatrixSession ensureSession,
    required MeetingPlaceMatrixSDKLogger logger,
  }) : _ensureSession = ensureSession,
       _logger = logger;

  final EnsureMatrixSession _ensureSession;
  final MeetingPlaceMatrixSDKLogger _logger;

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

  /// Injects the [matrix.VoIP] instance required for MatrixRTC call management.
  ///
  /// Must be called once at app startup before [startCall], [leaveCall], or
  /// [watchCall]. The VoIP instance must be created in the Flutter layer using
  /// a concrete [matrix.WebRTCDelegate] implementation.
  void initializeVoIP(matrix.VoIP voip) {
    _voip = voip;
  }

  /// Creates a [matrix.VoIP] instance from [delegate] and an authenticated
  /// client for [didManager], then stores it for call operations.
  ///
  /// Preferred over [initializeVoIP] when the caller cannot hold a
  /// [matrix.Client] reference directly. Must be called before [startCall].
  Future<void> initializeVoIPWithDelegate({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
  }) async {
    final client = await _ensureSession(didManager);
    _voip = matrix.VoIP(client, delegate);
  }

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

    final client = await _ensureSession(didManager);
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

  /// Returns `true` when [roomId] already has at least one non-expired
  /// `m.call.member` state event, i.e. a MatrixRTC call is already in
  /// progress.
  ///
  /// Used to make call initiation idempotent: a caller that re-enters a room
  /// it already published a membership for (for example after an app restart)
  /// must rejoin the existing call instead of broadcasting a fresh
  /// call-invite. Returns `false` when VoIP is not initialised or the room
  /// has not yet synced.
  Future<bool> hasActiveCallMembership({
    required DidManager didManager,
    required String roomId,
  }) async =>
      (await activeCallId(didManager: didManager, roomId: roomId)) != null;

  /// Returns the callId of the first non-expired MatrixRTC call membership in
  /// [roomId], or `null` when no call is in progress.
  ///
  /// A device joining or rejoining an in-progress call must reuse this exact
  /// callId so its E2EE key exchange lands in the same call generation. A
  /// fresh caller passes a newly minted callId instead, so stale to-device
  /// encryption keys from a previous, ended call generation are routed to a
  /// dead session and dropped rather than overwriting the current key.
  ///
  /// Returns `null` when VoIP is not initialised or the room has not synced.
  Future<String?> activeCallId({
    required DidManager didManager,
    required String roomId,
  }) async {
    final voip = _voip;
    if (voip == null) return null;

    final client = await _ensureSession(didManager);
    final room = client.getRoomById(roomId);
    if (room == null) return null;

    final ownUserId = client.userID;
    final ownDeviceId = client.deviceID;

    for (final memberships in callMembershipsFromRoom(room, voip).values) {
      for (final membership in memberships) {
        if (membership.isExpired) continue;
        if (ownUserId != null &&
            ownDeviceId != null &&
            _isOwnDeviceMembership(membership, ownUserId, ownDeviceId)) {
          continue;
        }
        return membership.callId;
      }
    }
    return null;
  }

  /// Creates or joins a MatrixRTC group call in [roomId] using the LiveKit
  /// SFU backend.
  ///
  /// Publishes an `m.call.member` state event so the remote party can
  /// discover the LiveKit room. Call [initializeVoIP] before invoking this.
  ///
  /// Parameters:
  /// - [didManager]: The DID manager for the local participant.
  /// - [roomId]: Matrix room ID for the call.
  /// - [livekitServiceUrl]: WebSocket URL of the LiveKit server.
  /// - [livekitAlias]: Unique call identifier within the LiveKit server.
  /// - [callId]: Stable MatrixRTC call ID; defaults to [roomId].
  Future<matrix.GroupCallSession> startCall({
    required DidManager didManager,
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) async {
    final voip = _voip;
    if (voip == null) throw MatrixServiceException.voipNotInitialized();

    final client = await _ensureSession(didManager);
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

  /// Returns a stream of [matrix.MatrixRTCCallEvent]s for the given call.
  ///
  /// Returns `null` if VoIP is not initialized or no session exists for the
  /// given IDs.
  Stream<matrix.MatrixRTCCallEvent>? watchCall({
    required String roomId,
    required String callId,
  }) {
    return _voip?.getGroupCallById(roomId, callId)?.matrixRTCEventStream.stream;
  }

  /// Cancels the incoming-group-call subscription and clears pending
  /// activations. Safe to call multiple times. Does not dispose the VoIP
  /// instance itself, which is owned by the Flutter layer that created it.
  Future<void> dispose() async {
    await _incomingGroupCallSubscription?.cancel();
    _incomingGroupCallSubscription = null;
    _incomingCallListenerVoip = null;
    _pendingActivations.clear();
  }

  // ------------------------------------------------------------------
  // Private helpers
  // ------------------------------------------------------------------

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

  /// Completes any pending activations whose group calls have appeared in [voip].
  ///
  /// Completes only those activations whose group call session now exists and
  /// whose completer is not yet resolved. Safe to call multiple times.
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
      for (final memberships in callMembershipsFromRoom(room, voip).values) {
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

  /// Returns the first group call session in [voip] that belongs to [roomId],
  /// or `null` if none exists.
  matrix.GroupCallSession? _findGroupCallForRoom(
    matrix.VoIP voip,
    String roomId,
  ) {
    for (final entry in voip.groupCalls.entries) {
      if (entry.key.roomId == roomId) return entry.value;
    }
    return null;
  }

  /// Returns `true` if [membership] belongs to this device.
  bool _isOwnDeviceMembership(
    matrix.CallMembership membership,
    String ownUserId,
    String ownDeviceId,
  ) => membership.userId == ownUserId && membership.deviceId == ownDeviceId;

  /// Returns the MatrixRTC call memberships for [room].
  ///
  /// Extracted to allow test subclasses to inject controlled membership data
  /// without needing to populate the full room state event structure that
  /// the `getCallMembershipsFromRoom` extension reads.
  @visibleForTesting
  Map<String, List<matrix.CallMembership>> callMembershipsFromRoom(
    matrix.Room room,
    matrix.VoIP voip,
  ) => room.getCallMembershipsFromRoom(voip);
}
