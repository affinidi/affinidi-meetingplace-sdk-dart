import "dart:convert";

import "package:crypto/crypto.dart";
import "package:matrix/matrix.dart" as matrix;
import "package:uuid/uuid.dart";

import "../../loggers/meeting_place_core_sdk_logger.dart";
import "../../utils/string.dart";

class MatrixService {
  MatrixService({
    required matrix.Client matrixClient,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _matrixClient = matrixClient,
       _logger = logger;

  final matrix.Client _matrixClient;
  final MeetingPlaceCoreSDKLogger? _logger;
  matrix.VoIP? _voip;

  // TODO: generate and persist password securely - this is just for testing
  static final String _passwordPlaceholder = 'dummy_password';
  static final String _authenticationType = 'm.login.dummy';
  static const String _roomEncryptionAlgorithm = 'm.megolm.v1.aes-sha2';

  static final String _logKey = 'MatrixService';

  Stream<matrix.Event> get timelineEventStream =>
      _matrixClient.onTimelineEvent.stream.map((event) {
        _logEncryptionDetails(event);
        return event;
      });

  void _logEncryptionDetails(matrix.Event event) {
    final encryptedSource = event.originalSource;
    final cameFromEncryptedEvent =
        encryptedSource?.type == matrix.EventTypes.Encrypted ||
        event.type == matrix.EventTypes.Encrypted;

    if (!cameFromEncryptedEvent) {
      return;
    }

    final ciphertext = encryptedSource?.content['ciphertext'];
    final roomId = event.roomId;
    final sessionId = encryptedSource?.content['session_id'];
    final senderKey = encryptedSource?.content['sender_key'];

    _logger?.info(
      '''Matrix encryption details: roomId=${roomId == null ? 'unknown' : roomId.topAndTail()}, decryptedType=${event.type}, rawType=${encryptedSource?.type ?? event.type}, algorithm=${encryptedSource?.content['algorithm']}, ciphertextLength=${ciphertext is String ? ciphertext.length : 0}, sessionId=${sessionId is String ? sessionId.topAndTail() : sessionId}, senderKey=${senderKey is String ? senderKey.topAndTail() : senderKey}, body=${event.content['body']}''',
      name: _logKey,
    );
  }

  void _warnIfEncryptionUnavailable(String action) {
    if (_matrixClient.encryptionEnabled) {
      return;
    }

    _logger?.warning(
      '''Matrix end-to-end encryption is not enabled after $action. Messages in encrypted rooms require Vodozemac to be initialized before Matrix login/registration.''',
      name: _logKey,
    );
  }

  void _requireEncryptionReady() {
    if (_matrixClient.encryptionEnabled) {
      return;
    }

    throw StateError(
      'Matrix end-to-end encryption is not enabled. Initialize Vodozemac before logging into the Matrix client.',
    );
  }

  String _toMatrixDeviceId(String deviceToken) =>
      md5.convert(utf8.encode(deviceToken)).toString();

  Future<matrix.Room> _getRoom(String roomId) async {
    var room = _matrixClient.getRoomById(roomId);
    if (room != null) {
      return room;
    }

    await _matrixClient.waitForRoomInSync(roomId, join: true);
    room = _matrixClient.getRoomById(roomId);
    if (room == null) {
      throw StateError(
        'Matrix room $roomId is not available in the local sync state.',
      );
    }

    return room;
  }

  /// Injects the [matrix.VoIP] instance required for MatrixRTC call management.
  /// Must be called before [startCall], [leaveCall], or [watchCall].
  /// The VoIP instance must be created in the Flutter layer with a real
  /// [matrix.WebRTCDelegate] implementation.
  void initializeVoIP(matrix.VoIP voip) {
    _voip = voip;
    _logger?.info('VoIP initialized for MatrixRTC', name: _logKey);
  }

  Future<String> register({
    required String permanentChannelDid,
    required String deviceId,
  }) async {
    final hashedUsername = md5
        .convert(utf8.encode(permanentChannelDid))
        .toString();
    final matrixDeviceId = _toMatrixDeviceId(deviceId);

    // Logout first to ensure a clean state
    if (_matrixClient.accessToken != null) {
      final keepHomeserver = _matrixClient.homeserver;
      _logger?.info(
        'Logging out from MATRIX homeserver to ensure clean state for registration',
        name: _logKey,
      );
      await _matrixClient.logout();
      _matrixClient.homeserver = keepHomeserver;
    }

    final response = await _matrixClient.register(
      username: hashedUsername,
      password: _passwordPlaceholder,
      deviceId: matrixDeviceId,
      initialDeviceDisplayName: permanentChannelDid,
      auth: matrix.AuthenticationData(type: _authenticationType),
    );

    _logger?.info('''Device registered on MATRIX homeserver for
        DID: ${permanentChannelDid.topAndTail()}, using id
        ${response.userId.topAndTail()} and
      deviceId ${matrixDeviceId.topAndTail()}''', name: _logKey);

    _warnIfEncryptionUnavailable('Matrix registration');

    return response.userId;
  }

  Future<String> login({required String did, required String deviceId}) async {
    final hashedUsername = md5.convert(utf8.encode(did)).toString();
    final matrixDeviceId = _toMatrixDeviceId(deviceId);

    if (_matrixClient.accessToken != null) {
      final keepHomeserver = _matrixClient.homeserver;
      _logger?.info(
        'Logging out from MATRIX homeserver to ensure clean state for registration',
        name: _logKey,
      );
      await _matrixClient.logout();
      _matrixClient.homeserver = keepHomeserver;
    }

    final response = await _matrixClient.login(
      matrix.LoginType.mLoginPassword,
      user: hashedUsername,
      password: _passwordPlaceholder,
      deviceId: matrixDeviceId,
    );

    _warnIfEncryptionUnavailable('Matrix login');

    return response.userId;
  }

  Future<String> createRoomForGroup() async {
    _requireEncryptionReady();

    final roomId = await _matrixClient.createGroupChat(
      enableEncryption: true,
      waitForSync: true,
    );

    _logger?.info(
      '''Created encrypted MATRIX room ${roomId.topAndTail()} for group using $_roomEncryptionAlgorithm''',
      name: _logKey,
    );

    return roomId;
  }

  Future<void> inviteUserToRoom({
    required String userId,
    required String roomId,
  }) async {
    await _matrixClient.inviteUser(roomId, userId);

    _logger?.info('''Invited user ${userId.topAndTail()} to MATRIX room
        ${roomId.topAndTail()}''', name: _logKey);
  }

  Future<void> joinRoom(String roomId) async {
    await _matrixClient.joinRoom(roomId);
    await _matrixClient.waitForRoomInSync(roomId, join: true);

    _logger?.info(
      '''Joined MATRIX room ${roomId.topAndTail()}''',
      name: _logKey,
    );
  }

  Future<String> sendMessage({
    required String roomId,
    required String message,
  }) async {
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final eventId = await room.sendTextEvent(
      message,
      txid: const Uuid().v4(),
      parseCommands: false,
      parseMarkdown: false,
      addMentions: false,
    );

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending to room $roomId.',
      );
    }

    _logger?.info('''Sent message with event id $eventId
      to MATRIX room ${roomId.topAndTail()}''', name: _logKey);

    return eventId;
  }

  /// Creates or joins a MatrixRTC group call in `roomId` using LiveKit SFU backend.
  ///
  /// - `livekitServiceUrl` — WebSocket URL of LiveKit server, e.g. "ws://localhost:7880"
  /// - `livekitAlias` — unique call identifier within the LiveKit server.
  /// - `callId` — stable MatrixRTC call ID; defaults to `roomId`.
  ///
  /// Requires `initializeVoIP` to have been called first.
  /// Returns the active `matrix.GroupCallSession`.
  Future<matrix.GroupCallSession> startCall({
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) async {
    final voip = _voip;
    if (voip == null) {
      throw StateError(
        'VoIP not initialized. Call initMatrixRTC() on MeetingPlaceCoreSDK first.',
      );
    }

    final room = _matrixClient.getRoomById(roomId);
    if (room == null) throw Exception('Matrix room not found: $roomId');

    final backend = matrix.LiveKitBackend(
      livekitServiceUrl: livekitServiceUrl,
      livekitAlias: livekitAlias,
      // TODO (Earl): what does it take to enable E2EE with LiveKit backend?
      e2eeEnabled: false,
    );

    final session = await voip.fetchOrCreateGroupCall(
      callId ?? roomId,
      room,
      backend,
      'm.call',
      'm.room',
      preShareKey: false,
    );

    try {
      await session.enter();
    } catch (e) {
      // GroupCallState.entered means we're already in this call — safe to continue.
      if (!e.toString().contains('entered')) rethrow;
    }

    _logger?.info(
      '''Started MatrixRTC call in room ${roomId.topAndTail()}''',
      name: _logKey,
    );

    return session;
  }

  /// Leaves the active MatrixRTC group call in `roomId` with the given `callId`.
  Future<void> leaveCall({
    required String roomId,
    required String callId,
  }) async {
    final session = _voip?.getGroupCallById(roomId, callId);
    if (session == null) return;

    await session.leave();

    _logger?.info(
      '''Left MatrixRTC call in room ${roomId.topAndTail()}''',
      name: _logKey,
    );
  }

  /// Returns a stream of `matrix.MatrixRTCCallEvent`s for the given call.
  /// Returns null if VoIP is not initialized or no session exists for the IDs.
  Stream<matrix.MatrixRTCCallEvent>? watchCall({
    required String roomId,
    required String callId,
  }) {
    return _voip?.getGroupCallById(roomId, callId)?.matrixRTCEventStream.stream;
  }
}
