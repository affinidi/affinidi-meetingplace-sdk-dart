import "dart:convert";

import "package:crypto/crypto.dart";
import "package:matrix/matrix.dart" as matrix;
import "package:matrix/src/utils/client_init_exception.dart";
import "package:uuid/uuid.dart";
import "package:vodozemac/vodozemac.dart" as vod;

import "../../loggers/meeting_place_core_sdk_logger.dart";
import "../../utils/string.dart";

/// Creates (or retrieves) a [matrix.Client] for the given DID.
/// Each DID must receive a dedicated client backed by its own persistent
/// database so that Olm identity keys are isolated per user.
typedef MatrixClientFactory = Future<matrix.Client> Function(String did);

class MatrixService {
  MatrixService({
    required MatrixClientFactory matrixClientFactory,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _matrixClientFactory = matrixClientFactory,
       _logger = logger;

  final MatrixClientFactory _matrixClientFactory;
  final MeetingPlaceCoreSDKLogger? _logger;
  matrix.VoIP? _voip;
  matrix.WebRTCDelegate? _webRTCDelegate;

  // One client per DID, lazily created by the factory.
  final Map<String, matrix.Client> _clients = {};

  // The most recently logged-in client — used for operations that do not
  // carry a DID (timeline stream, VoIP calls).
  matrix.Client? _activeClient;

  Future<matrix.Client> _clientFor(String did) async {
    if (_clients.containsKey(did)) return _clients[did]!;
    final client = await _matrixClientFactory(did);
    // Vodozemac must be initialized before client.init() so that the Matrix SDK
    // sets up encryption when restoring the session. If vod isn't ready,
    // client.init() skips encryption entirely (encryptionEnabled stays false),
    // defeating the session-reuse guard in login().
    await _ensureVodozemacInitialized();
    // Restore any previously stored session (access token, Olm account, rooms)
    // from the per-DID database. This is a no-op if no session was persisted
    // (e.g. first login or after a proper logout that cleared the DB).
    // waitForFirstSync/waitUntilLoadCompleted are false so this returns quickly;
    // the background sync loop is still started so the session stays fresh.
    try {
      await client.init(
        waitForFirstSync: false,
        waitUntilLoadCompletedLoaded: false,
      );
    } catch (e) {
      _logger?.warning(
        'DB session restore failed for DID ${did.topAndTail()}: $e. Will proceed with fresh login.',
        name: _logKey,
      );
    }
    _clients[did] = client;
    return client;
  }

  String? get accessToken => _matrixClient.accessToken;

  // TODO: generate and persist password securely - this is just for testing
  static final String _passwordPlaceholder = 'dummy_password';
  static final String _authenticationType = 'm.login.dummy';
  static const String _roomEncryptionAlgorithm = 'm.megolm.v1.aes-sha2';

  static final String _logKey = 'MatrixService';

  Future<Stream<matrix.Event>> timelineEventStream({
    required String did,
    required String deviceId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    return client.onTimelineEvent.stream.map((event) {
      _logEncryptionDetails(event);
      return event;
    });
  }

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

  static Future<void>? _vodozemacInitFuture;

  Future<void> _ensureVodozemacInitialized() async {
    if (vod.isInitialized()) return;
    _vodozemacInitFuture ??= vod.init();
    try {
      await _vodozemacInitFuture;
    } catch (e) {
      _vodozemacInitFuture = null;
      _logger?.warning(
        'Vodozemac initialization failed: $e. Matrix E2EE will not be available.',
        name: _logKey,
      );
    }
  }

  void _warnIfEncryptionUnavailable(String action) {
    if (_activeClient?.encryptionEnabled ?? false) {
      return;
    }

    _logger?.warning(
      '''Matrix end-to-end encryption is not enabled after $action. Messages in encrypted rooms require Vodozemac to be initialized before Matrix login/registration.''',
      name: _logKey,
    );
  }

  void _requireEncryptionReady() {
    if (_activeClient?.encryptionEnabled ?? false) {
      return;
    }

    throw StateError(
      'Matrix end-to-end encryption is not enabled. Initialize Vodozemac before logging into the Matrix client.',
    );
  }

  String _toMatrixDeviceId(String deviceToken) =>
      md5.convert(utf8.encode(deviceToken)).toString();

  Future<matrix.Room> _getRoom(String roomId) async {
    final client = _activeClient;
    if (client == null) {
      throw StateError('No active Matrix session when fetching room $roomId.');
    }

    var room = client.getRoomById(roomId);
    if (room != null) {
      return room;
    }

    await client.waitForRoomInSync(roomId, join: true);
    room = client.getRoomById(roomId);
    if (room == null) {
      throw StateError(
        'Matrix room $roomId is not available in the local sync state.',
      );
    }

    return room;
  }

  /// Stores the [matrix.WebRTCDelegate] to be used for MatrixRTC calls.
  /// The [matrix.VoIP] instance is created lazily per active client when
  /// a call is started, since [matrix.VoIP] is bound to a specific client.
  void initializeVoIP(matrix.WebRTCDelegate delegate) {
    _webRTCDelegate = delegate;
    // Reset any existing VoIP so it is recreated against the current active
    // client on the next startCall invocation.
    _voip = null;
    _logger?.info('WebRTC delegate set for MatrixRTC', name: _logKey);
  }

  Future<String> register({
    required String permanentChannelDid,
    required String deviceId,
  }) async {
    final client = await _clientFor(permanentChannelDid);
    final hashedUsername = md5
        .convert(utf8.encode(permanentChannelDid))
        .toString();
    final matrixDeviceId = _toMatrixDeviceId(deviceId);

    // Logout first to ensure a clean state for (re-)registration.
    if (client.accessToken != null) {
      final keepHomeserver = client.homeserver;
      _logger?.info(
        'Logging out from MATRIX homeserver to ensure clean state for registration',
        name: _logKey,
      );
      await client.logout();
      client.homeserver = keepHomeserver;
    }

    await _ensureVodozemacInitialized();

    final response = await client.register(
      username: hashedUsername,
      password: _passwordPlaceholder,
      deviceId: matrixDeviceId,
      initialDeviceDisplayName: permanentChannelDid,
      auth: matrix.AuthenticationData(type: _authenticationType),
    );

    _activeClient = client;
    _logger?.info('''Device registered on MATRIX homeserver for
        DID: ${permanentChannelDid.topAndTail()}, using id
        ${response.userId.topAndTail()} and
      deviceId ${matrixDeviceId.topAndTail()}''', name: _logKey);

    _warnIfEncryptionUnavailable('Matrix registration');

    return response.userId;
  }

  Future<String> login({required String did, required String deviceId}) async {
    final client = await _clientFor(did);
    final hashedUsername = md5.convert(utf8.encode(did)).toString();
    final matrixDeviceId = _toMatrixDeviceId(deviceId);

    // `_clientFor` already called `client.init()` which restored the full
    // session from the per-DID SQLite DB — Olm account, inbound Megolm group
    // sessions, room state, prevBatch, etc. If that restored session matches
    // the expected device and has working encryption, reuse it directly.
    // Calling logout() here would invoke clear() which wipes the entire DB,
    // destroying all received room keys and causing
    // "The sender has not sent us the session key" on any decryption attempt.
    if (client.accessToken != null &&
        client.deviceID == matrixDeviceId &&
        client.encryptionEnabled) {
      _activeClient = client;
      _logger?.info(
        'Reusing restored Matrix session for DID ${did.topAndTail()}',
        name: _logKey,
      );
      return client.userID!;
    }

    // Per the Matrix spec, a device's ed25519 identity key MUST NOT change
    // after it has been published (spec: POST /keys/upload). Save the Olm
    // pickle from this DID's own client before logout so it can be restored if
    // the homeserver rejects a fresh key upload for this device.
    String? savedOlmPickle;
    if (client.accessToken != null && client.deviceID == matrixDeviceId) {
      savedOlmPickle = client.encryption?.pickledOlmAccount;
    }

    if (client.accessToken != null) {
      final keepHomeserver = client.homeserver;
      _logger?.info(
        'Logging out from MATRIX homeserver to ensure clean state for login',
        name: _logKey,
      );
      await client.logout();
      client.homeserver = keepHomeserver;
    }

    await _ensureVodozemacInitialized();

    try {
      final response = await client.login(
        matrix.LoginType.mLoginPassword,
        identifier: matrix.AuthenticationUserIdentifier(user: hashedUsername),
        password: _passwordPlaceholder,
        deviceId: matrixDeviceId,
      );
      _activeClient = client;
      _warnIfEncryptionUnavailable('Matrix login');

      return response.userId;
    } on ClientInitException catch (e) {
      // The homeserver rejected our key upload because this device already has
      // ed25519 keys registered from a previous session. Recover by re-running
      // init() with the preserved Olm account so the same keys are reused.
      final recoveryToken = e.accessToken;
      final recoveryHomeserver = e.homeserver;
      final recoveryUserId = e.userId;
      final recoveryDeviceId = e.deviceId ?? matrixDeviceId;
      if (recoveryToken != null &&
          recoveryHomeserver != null &&
          recoveryUserId != null &&
          savedOlmPickle != null) {
        _logger?.info(
          'Restoring preserved Olm account for re-login of DID ${did.topAndTail()}',
          name: _logKey,
        );
        await client.init(
          newToken: recoveryToken,
          newHomeserver: recoveryHomeserver,
          newUserID: recoveryUserId,
          newDeviceID: recoveryDeviceId,
          newOlmAccount: savedOlmPickle,
        );
        _activeClient = client;
        _warnIfEncryptionUnavailable('Matrix re-login');
        return recoveryUserId;
      }
      _logger?.error(
        'Matrix login failed for DID ${did.topAndTail()} with error: $e',
        name: _logKey,
      );
      rethrow;
    } catch (e) {
      _logger?.error(
        'Matrix login failed for DID ${did.topAndTail()} with error: $e',
        name: _logKey,
      );
      rethrow;
    }
  }

  Future<String> ensureLoggedIn({
    required String did,
    required String deviceId,
  }) async {
    final client = await _clientFor(did);
    final expectedLocalpart = md5.convert(utf8.encode(did)).toString();
    final expectedMatrixDeviceId = _toMatrixDeviceId(deviceId);

    final accessToken = client.accessToken;
    final currentUserId = client.userID;
    final currentDeviceId = client.deviceID;

    if (accessToken == null) {
      _logger?.info(
        'Matrix client is not logged in; logging in before room operations',
        name: _logKey,
      );
      return login(did: did, deviceId: deviceId);
    }

    bool matchesExpectedUser = false;
    if (currentUserId != null && currentUserId.startsWith('@')) {
      final colonIndex = currentUserId.indexOf(':');
      if (colonIndex > 1) {
        final localpart = currentUserId.substring(1, colonIndex);
        matchesExpectedUser = localpart == expectedLocalpart;
      }
    }

    final matchesExpectedDevice =
        currentDeviceId != null && currentDeviceId == expectedMatrixDeviceId;

    if (!matchesExpectedUser || !matchesExpectedDevice) {
      _logger?.warning(
        '''Matrix client appears to be logged in as a different user/device (currentUserId=${currentUserId ?? 'unknown'}, currentDeviceId=${currentDeviceId ?? 'unknown'}). Re-authenticating for did=${did.topAndTail()}''',
        name: _logKey,
      );
      return login(did: did, deviceId: deviceId);
    }

    // If the session is valid but encryption was never set up (e.g. device was
    // registered before Vodozemac was initialised), force a re-login so that
    // Vodozemac is initialised and device keys are uploaded. Without this the
    // Matrix SDK reports "Invalid device" for every key query.
    if (!client.encryptionEnabled) {
      _logger?.warning(
        'Matrix encryption not enabled on existing session; re-authenticating to upload device keys for did=${did.topAndTail()}',
        name: _logKey,
      );
      return login(did: did, deviceId: deviceId);
    }

    _activeClient = client;
    return currentUserId!;
  }

  Future<String> createRoomForGroup({
    required String did,
    required String deviceId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    _requireEncryptionReady();

    final roomId = await _activeClient!.createGroupChat(
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
    required String did,
    required String deviceId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    await _activeClient!.inviteUser(roomId, userId);

    _logger?.info('''Invited user ${userId.topAndTail()} to MATRIX room
        ${roomId.topAndTail()}''', name: _logKey);
  }

  Future<void> joinRoom(
    String roomId, {
    required String did,
    required String deviceId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _activeClient!;

    await client.joinRoom(roomId);
    await client.waitForRoomInSync(roomId, join: true);

    _logger?.info(
      '''Joined MATRIX room ${roomId.topAndTail()}''',
      name: _logKey,
    );
  }

  Future<String> sendFile({
    required String roomId,
    required matrix.MatrixFile file,
  }) async {
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final eventId = await room.sendFileEvent(file, txid: const Uuid().v4());

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending to room $roomId.',
      );
    }

    _logger?.info('''Sent file with event id $eventId
      to MATRIX room ${roomId.topAndTail()}''', name: _logKey);

    return eventId;
  }

  /// Sends an image message to a Matrix room by referencing an existing
  /// `mxc://...` media URI.
  ///
  /// This does **not** upload or encrypt the media itself. In encrypted rooms
  /// the message event will be encrypted by the Matrix SDK, but the media
  /// remains plaintext on the homeserver.
  Future<String> sendImageByMxcUri({
    required String roomId,
    required String mxcUri,
    String? filename,
    String? mimeType,
    int? size,
    int? width,
    int? height,
  }) async {
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final body = filename?.isNotEmpty == true ? filename! : 'image';

    final content = <String, dynamic>{
      'msgtype': matrix.MessageTypes.Image,
      'body': body,
      'url': mxcUri,
      if (filename != null && filename.isNotEmpty) 'filename': filename,
      'info': {
        if (mimeType != null && mimeType.isNotEmpty) 'mimetype': mimeType,
        if (size != null) 'size': size,
        if (width != null) 'w': width,
        if (height != null) 'h': height,
      },
    };

    final eventId = await room.sendEvent(content, txid: const Uuid().v4());

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending to room $roomId.',
      );
    }

    _logger?.info(
      '''Sent image mxcUri=${mxcUri.toString().topAndTail()}
      with event id $eventId to MATRIX room ${roomId.topAndTail()}''',
      name: _logKey,
    );

    return eventId;
  }

  Future<String> sendMessage({
    required String roomId,
    required String message,
    required String did,
    required String deviceId,
    bool notify = false,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final eventId = await room.sendTextEvent(
      message,
      txid: const Uuid().v4(),
      parseCommands: false,
      parseMarkdown: false,
      addMentions: notify,
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
    final delegate = _webRTCDelegate;
    if (delegate == null) {
      throw StateError(
        'VoIP not initialized. Call initMatrixRTC() on MeetingPlaceCoreSDK first.',
      );
    }

    final client = _activeClient;
    if (client == null) {
      throw StateError(
        'No active Matrix session. Ensure a user is logged in before starting a call.',
      );
    }

    // Recreate VoIP if the active client has changed since last call.
    if (_voip?.client != client) {
      _voip = matrix.VoIP(client, delegate);
    }
    final voip = _voip!;

    final room = client.getRoomById(roomId);
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
