import "dart:convert";
import 'dart:typed_data';

import "package:crypto/crypto.dart";
import 'package:didcomm/didcomm.dart' show Attachment, AttachmentData;
import "package:matrix/matrix.dart" as matrix;
import 'package:matrix/matrix_api_lite/generated/fixed_model.dart'
    as matrix_api;
import "package:matrix/src/utils/client_init_exception.dart";
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import "package:uuid/uuid.dart";
import "package:vodozemac/vodozemac.dart" as vod;

import "../../loggers/meeting_place_core_sdk_logger.dart";
import '../../protocol/attachment/attachment_format.dart';
import '../../repository/key_repository.dart';
import "../../utils/string.dart";

enum _MatrixAttachmentKind { image, audio }

/// Creates (or retrieves) a [matrix.Client] for the given DID.
/// Each DID must receive a dedicated client backed by its own persistent
/// database so that Olm identity keys are isolated per user.
typedef MatrixClientFactory = Future<matrix.Client> Function(String did);

class MatrixService {
  MatrixService({
    required MatrixClientFactory matrixClientFactory,
    required KeyRepository keyRepository,
    required ControlPlaneSDK controlPlaneSDK,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _matrixClientFactory = matrixClientFactory,
       _keyRepository = keyRepository,
       _controlPlaneSDK = controlPlaneSDK,
       _logger = logger;

  final MatrixClientFactory _matrixClientFactory;
  final KeyRepository _keyRepository;
  final ControlPlaneSDK _controlPlaneSDK;
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

  Future<String> uploadMedia(
    Uint8List data, {
    String? filename,
    String? contentType,
  }) async {
    final client = _activeClient;
    if (client == null) {
      throw StateError(
        'No active Matrix session. Ensure a user is logged in before uploading media.',
      );
    }

    final mxcUri = await client.uploadContent(
      data,
      filename: filename,
      contentType: contentType,
    );

    return mxcUri.toString();
  }

  Future<Attachment> sendAttachment({
    required String roomId,
    required Attachment attachment,
  }) async {
    final attachmentKind = _attachmentKindFrom(attachment);
    if (attachmentKind == null) {
      throw StateError(
        'Unsupported Matrix attachment type format=${attachment.format} mediaType=${attachment.mediaType}.',
      );
    }

    final filename =
        attachment.filename ?? _defaultAttachmentFilename(attachmentKind);
    final mediaType = attachment.mediaType ?? 'application/octet-stream';
    final format = _attachmentFormatForKind(
      attachment: attachment,
      attachmentKind: attachmentKind,
    );
    final existingData = attachment.data;
    final existingLinks = existingData?.links;
    final existingUri = existingLinks != null && existingLinks.isNotEmpty
        ? existingLinks.first.toString()
        : null;
    final matrixUri = (existingUri != null && existingUri.isNotEmpty)
        ? existingUri
        : await _uploadAttachmentToMatrix(
            attachment: attachment,
            filename: filename,
            mediaType: mediaType,
          );
    final byteCount =
        attachment.byteCount ?? _byteCountFromBase64(attachment.data?.base64);

    await _dispatchAttachmentByKind(
      attachmentKind: attachmentKind,
      roomId: roomId,
      uri: matrixUri,
      filename: filename,
      mediaType: mediaType,
      format: format,
      byteCount: byteCount,
      durationMs: _attachmentDurationMs(attachment),
    );

    return Attachment(
      id: attachment.id,
      description: attachment.description,
      filename: filename,
      mediaType: mediaType,
      format: format,
      lastModifiedTime: attachment.lastModifiedTime,
      data: AttachmentData(
        base64: existingData?.base64,
        jws: existingData?.jws,
        hash: existingData?.hash,
        json: existingData?.json,
        links: [Uri.parse(matrixUri)],
      ),
      byteCount: byteCount,
    );
  }

  /// Downloads media from the Matrix content repository for an `mxc://...` URI.
  ///
  /// Returns a [matrix.FileResponse] containing the raw bytes and (if available)
  /// the detected content type.
  Future<matrix_api.FileResponse> downloadMediaByUri({
    required String did,
    required String deviceId,
    required String uri,
    bool allowRemote = true,
    int? timeoutMs,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);

    final mediaUri = Uri.parse(uri);
    if (mediaUri.authority.isEmpty || mediaUri.pathSegments.isEmpty) {
      throw FormatException('Invalid URI: $uri');
    }

    final serverName = mediaUri.authority;
    final mediaId = mediaUri.pathSegments.first;

    final client = _clients[did]!;
    return client.getContent(
      serverName,
      mediaId,
      allowRemote: allowRemote,
      timeoutMs: timeoutMs,
    );
  }

  Future<Attachment> downloadAttachment({
    required String did,
    required String deviceId,
    required Attachment attachment,
    bool allowRemote = true,
    int? timeoutMs,
  }) async {
    final uri = attachment.data?.links?.firstOrNull?.toString();
    if (uri == null) {
      throw StateError(
        'Attachment ${attachment.id} does not have base64 data or a Matrix media link.',
      );
    }

    final file = await downloadMediaByUri(
      did: did,
      deviceId: deviceId,
      uri: uri,
      allowRemote: allowRemote,
      timeoutMs: timeoutMs,
    );

    return _attachmentWithDownloadedData(attachment, file);
  }

  static const String _didAuthLoginType = 'org.affinidi.login.did_auth';
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

  /// Returns the Matrix userId for a DID on the currently configured homeserver.
  ///
  /// Meeting Place uses `md5(did)` as the Matrix localpart. The server name is
  /// derived from the currently logged-in user's Matrix ID.
  Future<String> matrixUserIdForDid({
    required String did,
    required String deviceId,
    required String targetDid,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    final selfUserId = client.userID;
    if (selfUserId == null) {
      throw StateError('Matrix userId is not available after login.');
    }

    final colonIndex = selfUserId.indexOf(':');
    if (colonIndex < 0 || colonIndex == selfUserId.length - 1) {
      throw StateError('Invalid Matrix userId format: $selfUserId');
    }
    final serverName = selfUserId.substring(colonIndex + 1);
    final localpart = md5.convert(utf8.encode(targetDid)).toString();
    return '@$localpart:$serverName';
  }

  /// Returns the joined/invited direct-chat roomId for the given Matrix user ID,
  /// if present in the local account data (`m.direct`).
  ///
  /// Does not create a new room.
  Future<String?> getExistingDirectChatRoomId({
    required String did,
    required String deviceId,
    required String otherMatrixUserId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    return client.getDirectChatFromUserId(otherMatrixUserId);
  }

  /// Returns an existing direct room ID with `otherMatrixUserId` or creates a
  /// new one if none exists.
  Future<String> ensureDirectChatRoom({
    required String did,
    required String deviceId,
    required String otherMatrixUserId,
    bool waitForSync = true,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    return client.startDirectChat(otherMatrixUserId, waitForSync: waitForSync);
  }

  /// Sends a Matrix typing notification (`m.typing`) for `roomId`.
  ///
  /// `timeoutMs` is how long the server should consider the user typing.
  Future<void> setTyping({
    required String did,
    required String deviceId,
    required String roomId,
    required bool isTyping,
    int? timeoutMs,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final room = await _getRoom(roomId);
    await room.setTyping(isTyping, timeout: timeoutMs);
  }

  /// Emits the current list of typing Matrix user IDs whenever the server sends
  /// an `m.typing` ephemeral update for `roomId`.
  Stream<List<String>> typingUserIdsStream({
    required String did,
    required String deviceId,
    required String roomId,
    bool excludeSelf = true,
  }) async* {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;

    // Ensure room is present in the local sync state.
    await client.waitForRoomInSync(roomId, join: true);
    final room = client.getRoomById(roomId);
    if (room == null) {
      throw StateError('Matrix room not found after sync: $roomId');
    }

    Set<String>? lastEmitted;

    List<String> currentTypingUserIds() {
      final ids = room.typingUsers.map((u) => u.id).whereType<String>();
      final filtered = excludeSelf && client.userID != null
          ? ids.where((id) => id != client.userID)
          : ids;
      final unique = filtered.toSet();
      return unique.toList()..sort();
    }

    // Emit the current state immediately (helps consumers initialise UI).
    final initial = currentTypingUserIds();
    lastEmitted = initial.toSet();
    yield initial;

    await for (final sync in client.onSync.stream) {
      final joinedRoomUpdate = sync.rooms?.join?[roomId];
      if (joinedRoomUpdate == null) continue;

      final ephemerals = joinedRoomUpdate.ephemeral;
      if (ephemerals == null || ephemerals.isEmpty) continue;
      final hasTypingUpdate = ephemerals.any((e) => e.type == 'm.typing');
      if (!hasTypingUpdate) continue;

      final next = currentTypingUserIds();
      final nextSet = next.toSet();
      if (lastEmitted != null && lastEmitted.length == nextSet.length) {
        bool equal = true;
        for (final id in nextSet) {
          if (!lastEmitted.contains(id)) {
            equal = false;
            break;
          }
        }
        if (equal) continue;
      }

      lastEmitted = nextSet;
      yield next;
    }
  }

  /// Sets the local user's Matrix presence state.
  ///
  /// This uses the standard Matrix presence API:
  /// `PUT /_matrix/client/v3/presence/{userId}/status`.
  Future<void> setPresence({
    required String did,
    required String deviceId,
    required matrix.PresenceType presence,
    String? statusMsg,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    final userId = client.userID;
    if (userId == null) {
      throw StateError('Matrix userId is not available after login.');
    }

    // The Matrix /sync request omits `set_presence` by default, which causes
    // the server to automatically mark the user as online on every sync poll.
    // This overrides an explicit setPresence(offline) call within ~30 seconds.
    // To prevent that, we keep `client.syncPresence` aligned with the explicit
    // presence: setting offline here also makes subsequent syncs send
    // `set_presence=offline`, locking in the offline state. Setting online
    // resets it to null so the server's default (online) behaviour returns.
    client.syncPresence = presence == matrix.PresenceType.online
        ? null
        : presence;

    await client.setPresence(userId, presence, statusMsg: statusMsg);
  }

  /// Emits Matrix presence updates observed via `/sync`.
  ///
  /// If [userIds] is provided, only presence updates for those MXIDs are
  /// forwarded.
  Stream<matrix.CachedPresence> presenceStream({
    required String did,
    required String deviceId,
    Set<String>? userIds,
  }) async* {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;

    await for (final presence in client.onPresenceChanged.stream) {
      if (userIds != null && !userIds.contains(presence.userid)) continue;
      yield presence;
    }
  }

  /// Returns the currently cached [matrix.CachedPresence] for each of the
  /// given [userIds], reading directly from the in-memory `client.presences`
  /// map that is populated by the Matrix `/sync` loop.
  ///
  /// Only entries that are already cached are returned (no network call is
  /// made). Use this to seed the initial presence state when opening a chat
  /// screen, avoiding the wait for the next sync cycle.
  Future<List<matrix.CachedPresence>> getCachedPresences({
    required String did,
    required String deviceId,
    required Set<String> userIds,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    final client = _clients[did]!;
    // ignore: deprecated_member_use
    final presenceMap = client.presences;
    return userIds
        .map((id) => presenceMap[id])
        .whereType<matrix.CachedPresence>()
        .toList();
  }

  /// The Matrix-format identity for the local participant: `userId:deviceId`.
  ///
  /// This must be used as the LiveKit JWT `sub` so the LiveKit FrameCryptor
  /// can look up the encryption key by participant identity.
  String? get localMatrixIdentity {
    final userId = _activeClient?.userID;
    final deviceId = _activeClient?.deviceID;
    if (userId == null || deviceId == null) return null;
    return '$userId:$deviceId';
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

  Attachment _attachmentWithDownloadedData(
    Attachment attachment,
    matrix_api.FileResponse file,
  ) {
    final existingData = attachment.data;
    final contentType = attachment.mediaType?.trim();
    final downloadedContentType = file.contentType?.trim();
    final mediaType = (contentType != null && contentType.isNotEmpty)
        ? contentType
        : (downloadedContentType != null && downloadedContentType.isNotEmpty)
        ? downloadedContentType
        : 'application/octet-stream';
    final updatedData = AttachmentData(
      base64: base64Encode(file.data),
      jws: existingData?.jws,
      hash: existingData?.hash,
      json: existingData?.json,
      links: existingData?.links ?? const <Uri>[],
    );

    return Attachment(
      id: attachment.id,
      description: attachment.description,
      filename: attachment.filename,
      mediaType: mediaType,
      format: attachment.format,
      lastModifiedTime: attachment.lastModifiedTime,
      data: updatedData,
      byteCount: file.data.length,
    );
  }

  Future<matrix.Room> _getRoom(String roomId, {bool forceSync = false}) async {
    final client = _activeClient;
    if (client == null) {
      throw StateError('No active Matrix session when fetching room $roomId.');
    }

    if (forceSync) {
      await client.oneShotSync();
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

  /// Returns the current user's power level in the given Matrix [roomId].
  ///
  /// Set [forceSync] to `true` to fetch only the latest
  /// `m.room.power_levels` state event from the server before reading.
  /// This avoids a full `/sync` while still returning up-to-date power levels.
  Future<int> getOwnPowerLevel({
    required String roomId,
    bool forceSync = false,
  }) async {
    _logger?.info(
      'Getting own power level in room ${roomId.topAndTail()}',
      name: _logKey,
    );
    final client = _activeClient;
    if (client == null) {
      throw StateError('No active Matrix session.');
    }
    final room = await _getRoom(roomId);
    final powerLevelsContent = forceSync
        ? await _fetchRoomPowerLevelsContent(roomId: roomId, client: client)
        : null;
    final powerLevel = _powerLevelForUser(
      room: room,
      userId: client.userID!,
      powerLevelsContent: powerLevelsContent,
    );
    _logger?.info(
      'Own power level in room ${roomId.topAndTail()} is $powerLevel',
      name: _logKey,
    );
    return powerLevel;
  }

  /// Returns the power level of [targetDid] in [roomId].
  ///
  /// Set [forceSync] to `true` to fetch only the latest
  /// `m.room.power_levels` state event from the server before reading.
  /// This avoids a full `/sync` while still returning up-to-date power levels.
  Future<int> getMemberPowerLevel({
    required String roomId,
    required String targetDid,
    bool forceSync = false,
  }) async {
    _logger?.info(
      'Getting power level of ${targetDid.topAndTail()} in room ${roomId.topAndTail()}',
      name: _logKey,
    );
    final client = _activeClient;
    if (client == null) {
      throw StateError('No active Matrix session.');
    }
    final room = await _getRoom(roomId);
    final targetMatrixUserId = await _resolveTargetMatrixUserId(
      room: room,
      client: client,
      targetDid: targetDid,
    );
    final powerLevelsContent = forceSync
        ? await _fetchRoomPowerLevelsContent(roomId: roomId, client: client)
        : null;
    final powerLevel = _powerLevelForUser(
      room: room,
      userId: targetMatrixUserId,
      powerLevelsContent: powerLevelsContent,
    );
    _logger?.info(
      'Power level of $targetMatrixUserId in room ${roomId.topAndTail()} is $powerLevel with fetchedPowerLevelsState=${powerLevelsContent != null}',
      name: _logKey,
    );
    return powerLevel;
  }

  /// Sets the power level of [targetDid] in [roomId] to [powerLevel].
  ///
  /// Derives the target Matrix user ID from the DID using the MD5 localpart
  /// convention. The caller must have sufficient power level to modify others.
  Future<void> setMemberPowerLevel({
    required String roomId,
    required String targetDid,
    required int powerLevel,
  }) async {
    _logger?.info(
      'Setting power level of ${targetDid.topAndTail()} to $powerLevel in room ${roomId.topAndTail()}',
      name: _logKey,
    );
    final client = _activeClient;
    if (client == null) {
      throw StateError('No active Matrix session.');
    }
    final room = await _getRoom(roomId);
    final targetMatrixUserId = await _resolveTargetMatrixUserId(
      room: room,
      client: client,
      targetDid: targetDid,
    );
    final senderMatrixUserId = client.userID;
    if (senderMatrixUserId == null) {
      throw StateError('Matrix userId is not available after login.');
    }

    final powerLevelsState = room.getState(matrix.EventTypes.RoomPowerLevels);
    final powerLevelContent =
        powerLevelsState?.content.copy() ??
        <String, Object?>{
          'users': <String, Object?>{},
          'users_default': 0,
          'events_default': 0,
          'state_default': 50,
          'ban': 50,
          'kick': 50,
          'redact': 50,
          'invite': 0,
        };

    var users = powerLevelContent['users'];
    if (users is! Map<String, Object?>) {
      users = <String, Object?>{};
      powerLevelContent['users'] = users;
    }

    final senderPowerLevel = room.getPowerLevelByUserId(senderMatrixUserId);
    users[senderMatrixUserId] ??= senderPowerLevel > 0 ? senderPowerLevel : 100;
    users[targetMatrixUserId] = powerLevel;

    _logger?.info(
      'Updating m.room.power_levels in room ${roomId.topAndTail()} as $senderMatrixUserId with senderLevel=${users[senderMatrixUserId]} target=$targetMatrixUserId targetLevel=$powerLevel hasExistingState=${powerLevelsState != null}',
      name: _logKey,
    );

    await client.setRoomStateWithKey(
      roomId,
      matrix.EventTypes.RoomPowerLevels,
      '',
      powerLevelContent,
    );
    final updatedPowerLevelsContent = await _fetchRoomPowerLevelsContent(
      roomId: roomId,
      client: client,
    );
    final updatedPowerLevel = _powerLevelForUser(
      room: room,
      userId: targetMatrixUserId,
      powerLevelsContent: updatedPowerLevelsContent,
    );
    _logger?.info(
      'Set power level of $targetMatrixUserId to $powerLevel in room ${roomId.topAndTail()} and fetched back $updatedPowerLevel',
      name: _logKey,
    );
  }

  Future<Map<String, Object?>?> _fetchRoomPowerLevelsContent({
    required String roomId,
    required matrix.Client client,
  }) async {
    try {
      return await client.getRoomStateWithKey(
        roomId,
        matrix.EventTypes.RoomPowerLevels,
        '',
      );
    } on matrix.MatrixException catch (e) {
      if (e.errcode == 'M_NOT_FOUND') {
        return null;
      }
      rethrow;
    }
  }

  int _powerLevelForUser({
    required matrix.Room room,
    required String userId,
    Map<String, Object?>? powerLevelsContent,
  }) {
    if (powerLevelsContent == null) {
      return room.getPowerLevelByUserId(userId);
    }

    if (room.creatorUserIds.contains(userId) &&
        !((int.tryParse(room.roomVersion ?? '') ?? 0) < 12)) {
      return 9007199254740991;
    }

    final users = powerLevelsContent['users'];
    if (users is Map<String, Object?>) {
      final userSpecificPowerLevel = users[userId];
      if (userSpecificPowerLevel is int) {
        return userSpecificPowerLevel;
      }
      if (userSpecificPowerLevel is num) {
        return userSpecificPowerLevel.toInt();
      }
    }

    final defaultUserPowerLevel = powerLevelsContent['users_default'];
    if (defaultUserPowerLevel is int) {
      return defaultUserPowerLevel;
    }
    if (defaultUserPowerLevel is num) {
      return defaultUserPowerLevel.toInt();
    }

    return room.getPowerLevelByUserId(userId);
  }

  Future<String> _resolveTargetMatrixUserId({
    required matrix.Room room,
    required matrix.Client client,
    required String targetDid,
  }) async {
    final localpart = md5.convert(utf8.encode(targetDid)).toString();
    final prefix = '@$localpart:';

    String? findIn(Iterable<matrix.User> users) {
      for (final user in users) {
        final userId = user.id;
        if (userId.startsWith(prefix)) {
          return userId;
        }
      }
      return null;
    }

    final knownParticipants = room.getParticipants([
      matrix.Membership.join,
      matrix.Membership.invite,
    ]);
    final fromKnown = findIn(knownParticipants);
    if (fromKnown != null) return fromKnown;

    final requestedParticipants = await room.requestParticipants([
      matrix.Membership.join,
      matrix.Membership.invite,
    ], true);
    final fromRequested = findIn(requestedParticipants);
    if (fromRequested != null) return fromRequested;

    final selfUserId = client.userID;
    if (selfUserId == null) {
      throw StateError('Matrix userId is not available after login.');
    }
    final colonIndex = selfUserId.indexOf(':');
    final serverName = selfUserId.substring(colonIndex + 1);
    final fallbackUserId = '@$localpart:$serverName';

    _logger?.warning(
      'Could not resolve target user in room participants, falling back to $fallbackUserId',
      name: _logKey,
    );

    return fallbackUserId;
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

  Future<void> refreshStoredLoginCredential() async {
    final rootDidDoc = await _controlPlaneSDK.didManager.getDidDocument();
    final rootDid = rootDidDoc.id;
    final client = await _clientFor(rootDid);
    final homeserver = client.homeserver;
    if (homeserver == null) {
      throw StateError(
        'Matrix homeserver is not configured on the Matrix client.',
      );
    }

    final result = await _controlPlaneSDK.execute(
      MatrixRegistrationCredentialCommand(
        homeserver: client.homeserver.toString(),
      ),
    );
    final responseDid = result.did.trim();

    if (responseDid.isEmpty) {
      throw StateError(
        'Control Plane returned an empty Matrix credential DID.',
      );
    }

    if (responseDid != rootDid) {
      throw StateError(
        'Control Plane returned Matrix login credential for ${responseDid.topAndTail()} when ${rootDid.topAndTail()} was requested.',
      );
    }

    await _keyRepository.saveMatrixLoginCredential(jwt: result.credential);
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
      final loginToken = await _keyRepository.getMatrixLoginCredential();
      if (loginToken == null || loginToken.trim().isEmpty) {
        throw StateError(
          'Matrix login credential is not available for DID ${did.topAndTail()}. Register the device before logging in to Matrix.',
        );
      }

      final response = await client.login(
        _didAuthLoginType,
        identifier: matrix.AuthenticationUserIdentifier(user: hashedUsername),
        token: loginToken,
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

    // Explicitly set the creator at PL 100 and state_default at 50.
    // Without powerLevelContentOverride the homeserver uses implicit defaults,
    // which may not produce a local m.room.power_levels state event. When
    // room.powerLevels is null the SDK's setPower() sends a minimal content
    // that omits the creator, triggering M_FORBIDDEN on subsequent power-level
    // changes.
    final creatorMxid = _activeClient!.userID!;
    final roomId = await _activeClient!.createGroupChat(
      enableEncryption: true,
      waitForSync: true,
      powerLevelContentOverride: {
        'users': {creatorMxid: 100},
        'users_default': 0,
        'state_default': 50,
        'events_default': 0,
      },
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

  Future<String> _sendFileByMxcUri({
    required String roomId,
    required String mxcUri,
    required String msgType,
    required String fallbackBody,
    required String logLabel,
    String? filename,
    Map<String, dynamic>? info,
  }) async {
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final body = filename?.isNotEmpty == true ? filename! : fallbackBody;

    final content = <String, dynamic>{
      'msgtype': msgType,
      'body': body,
      'url': mxcUri,
      if (filename != null && filename.isNotEmpty) 'filename': filename,
      'info': info ?? <String, dynamic>{},
    };

    final eventId = await room.sendEvent(content, txid: const Uuid().v4());

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending to room $roomId.',
      );
    }

    _logger?.info(
      '''Sent $logLabel mxcUri=${mxcUri.toString().topAndTail()}
      with event id $eventId to MATRIX room ${roomId.topAndTail()}''',
      name: _logKey,
    );

    return eventId;
  }

  /// Sends an image message to a Matrix room by referencing an existing
  /// `mxc://...` media URI.
  ///
  /// This does **not** upload or encrypt the media itself. In encrypted rooms
  /// the message event will be encrypted by the Matrix SDK, but the media
  /// remains plaintext on the homeserver.
  Future<String> sendImageByUri({
    required String roomId,
    required String uri,
    String? filename,
    String? mimeType,
    String? format,
    int? size,
    int? width,
    int? height,
  }) async {
    return _sendFileByMxcUri(
      roomId: roomId,
      mxcUri: uri,
      msgType: matrix.MessageTypes.Image,
      fallbackBody: 'image',
      logLabel: 'image',
      filename: filename,
      info: {
        if (mimeType != null && mimeType.isNotEmpty) 'mimetype': mimeType,
        if (size != null) 'size': size,
        if (width != null) 'w': width,
        if (height != null) 'h': height,
        if (format != null && format.isNotEmpty) 'format': format,
      },
    );
  }

  /// Sends an audio message to a Matrix room by referencing an existing
  /// `mxc://...` media URI.
  ///
  /// This does **not** upload or encrypt the media itself. In encrypted rooms
  /// the message event will be encrypted by the Matrix SDK, but the media
  /// remains plaintext on the homeserver.
  Future<String> sendAudioByUri({
    required String roomId,
    required String mxcUri,
    String? filename,
    String? mimeType,
    int? size,
    int? durationMs,
    String? format,
  }) async {
    return _sendFileByMxcUri(
      roomId: roomId,
      mxcUri: mxcUri,
      msgType: matrix.MessageTypes.Audio,
      fallbackBody: 'audio',
      logLabel: 'audio',
      filename: filename,
      info: {
        if (mimeType != null && mimeType.isNotEmpty) 'mimetype': mimeType,
        if (size != null) 'size': size,
        if (durationMs != null) 'duration': durationMs,
        if (format != null && format.isNotEmpty) 'format': format,
      },
    );
  }

  Future<String> _uploadAttachmentToMatrix({
    required Attachment attachment,
    required String filename,
    required String mediaType,
  }) async {
    final base64 = attachment.data?.base64;
    if (base64 == null || base64.isEmpty) {
      throw StateError(
        'Attachment is missing base64 data and Matrix media link; cannot upload to Matrix media repository.',
      );
    }

    final bytes = base64Decode(base64);
    return uploadMedia(bytes, filename: filename, contentType: mediaType);
  }

  Future<void> _dispatchAttachmentByKind({
    required _MatrixAttachmentKind attachmentKind,
    required String roomId,
    required String uri,
    required String filename,
    required String mediaType,
    required String format,
    required int? byteCount,
    required int? durationMs,
  }) {
    switch (attachmentKind) {
      case _MatrixAttachmentKind.image:
        return sendImageByUri(
          roomId: roomId,
          uri: uri,
          filename: filename,
          mimeType: mediaType,
          size: byteCount,
          format: format,
        );
      case _MatrixAttachmentKind.audio:
        return sendAudioByUri(
          roomId: roomId,
          mxcUri: uri,
          filename: filename,
          mimeType: mediaType,
          size: byteCount,
          durationMs: durationMs,
          format: format,
        );
    }
  }

  _MatrixAttachmentKind? _attachmentKindFrom(Attachment attachment) {
    final format = attachment.format?.trim();
    if (format == AttachmentFormat.matrixImage.value) {
      return _MatrixAttachmentKind.image;
    }
    if (format == AttachmentFormat.matrixAudio.value) {
      return _MatrixAttachmentKind.audio;
    }

    final attachmentMetadata = _attachmentMetadata(attachment);
    final metadataFormat = _attachmentMetadataValue(
      attachmentMetadata,
      'format',
    );
    if (metadataFormat == AttachmentFormat.matrixImage.value) {
      return _MatrixAttachmentKind.image;
    }
    if (metadataFormat == AttachmentFormat.matrixAudio.value) {
      return _MatrixAttachmentKind.audio;
    }

    final messageType = _attachmentMetadataValue(attachmentMetadata, 'msgtype');
    if (messageType == matrix.MessageTypes.Image) {
      return _MatrixAttachmentKind.image;
    }
    if (messageType == matrix.MessageTypes.Audio) {
      return _MatrixAttachmentKind.audio;
    }

    final metadataMediaType = _attachmentMetadataValue(
      attachmentMetadata,
      'mimetype',
    )?.toLowerCase();
    if (metadataMediaType != null && metadataMediaType.isNotEmpty) {
      if (metadataMediaType.startsWith('image/')) {
        return _MatrixAttachmentKind.image;
      }
      if (metadataMediaType.startsWith('audio/')) {
        return _MatrixAttachmentKind.audio;
      }
    }

    final mediaType = attachment.mediaType?.trim().toLowerCase();
    if (mediaType == null || mediaType.isEmpty) {
      return null;
    }
    if (mediaType.startsWith('image/')) {
      return _MatrixAttachmentKind.image;
    }
    if (mediaType.startsWith('audio/')) {
      return _MatrixAttachmentKind.audio;
    }

    return null;
  }

  Map<String, dynamic>? _attachmentMetadata(Attachment attachment) {
    final attachmentJson = attachment.data?.json;
    if (attachmentJson == null || attachmentJson.isEmpty) {
      return null;
    }

    final decodedJson = jsonDecode(attachmentJson);
    if (decodedJson is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(decodedJson);
  }

  String? _attachmentMetadataValue(
    Map<String, dynamic>? attachmentMetadata,
    String key,
  ) {
    final value = attachmentMetadata?[key];
    if (value is! String) {
      return null;
    }

    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  String _attachmentFormatForKind({
    required Attachment attachment,
    required _MatrixAttachmentKind attachmentKind,
  }) {
    final format = attachment.format?.trim();
    if (format != null && format.isNotEmpty) {
      return format;
    }

    return _matrixAttachmentFormatValue(
      _attachmentFormatForKindEnum(attachmentKind),
    );
  }

  AttachmentFormat _attachmentFormatForKindEnum(
    _MatrixAttachmentKind attachmentKind,
  ) {
    switch (attachmentKind) {
      case _MatrixAttachmentKind.image:
        return AttachmentFormat.matrixImage;
      case _MatrixAttachmentKind.audio:
        return AttachmentFormat.matrixAudio;
    }
  }

  String _matrixAttachmentFormatValue(AttachmentFormat attachmentFormat) {
    return attachmentFormat.value;
  }

  String _defaultAttachmentFilename(_MatrixAttachmentKind attachmentKind) {
    switch (attachmentKind) {
      case _MatrixAttachmentKind.image:
        return 'image';
      case _MatrixAttachmentKind.audio:
        return 'audio';
    }
  }

  int? _byteCountFromBase64(String? base64) {
    if (base64 == null || base64.isEmpty) {
      return null;
    }

    return base64Decode(base64).length;
  }

  int? _attachmentDurationMs(Attachment attachment) {
    final attachmentMetadata = _attachmentMetadata(attachment);
    if (attachmentMetadata == null) {
      return null;
    }

    final durationValue =
        attachmentMetadata['durationMs'] ??
        attachmentMetadata['duration_ms'] ??
        attachmentMetadata['duration'];

    if (durationValue is int) {
      return durationValue;
    }
    if (durationValue is num) {
      return durationValue.toInt();
    }
    if (durationValue is String) {
      return int.tryParse(durationValue);
    }

    return null;
  }

  Future<String> sendMessage({
    required String roomId,
    required String message,
    required String did,
    required String deviceId,
    List<String>? mentionUserIds,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    _requireEncryptionReady();

    final room = await _getRoom(roomId);

    // When explicit mention targets are supplied, we build the event directly
    // so that `m.mentions.user_ids` is populated per the Matrix spec.
    // Relying on sendTextEvent + addMentions would only work if the IDs were
    // already embedded as @user:server patterns inside the message body.
    final String? eventId;
    if (mentionUserIds != null && mentionUserIds.isNotEmpty) {
      eventId = await room.sendEvent({
        'msgtype': matrix.MessageTypes.Text,
        'body': message,
        'm.mentions': {'user_ids': mentionUserIds},
      }, txid: const Uuid().v4());
    } else {
      eventId = await room.sendTextEvent(
        message,
        txid: const Uuid().v4(),
        parseCommands: false,
        parseMarkdown: false,
        addMentions: true,
      );
    }

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending to room $roomId.',
      );
    }

    _logger?.info('''Sent message with event id $eventId
      to MATRIX room ${roomId.topAndTail()}''', name: _logKey);

    return eventId;
  }

  /// Sends a Matrix reaction (`m.reaction`) to `targetEventId` in `roomId`.
  ///
  /// Uses an `m.annotation` relation with a `key` (emoji).
  Future<String> sendReaction({
    required String roomId,
    required String targetEventId,
    required String key,
    required String did,
    required String deviceId,
  }) async {
    await ensureLoggedIn(did: did, deviceId: deviceId);
    _requireEncryptionReady();

    final room = await _getRoom(roomId);
    final content = <String, dynamic>{
      'm.relates_to': <String, dynamic>{
        'rel_type': 'm.annotation',
        'event_id': targetEventId,
        'key': key,
      },
    };

    final eventId = await room.sendEvent(
      content,
      txid: const Uuid().v4(),
      type: 'm.reaction',
    );

    if (eventId == null) {
      throw StateError(
        'Matrix did not return an event ID when sending reaction to room $roomId.',
      );
    }

    _logger?.info(
      'Sent Matrix reaction key=$key to target=${targetEventId.topAndTail()} '
      'with event id ${eventId.topAndTail()} in room ${roomId.topAndTail()}',
      name: _logKey,
    );

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
      e2eeEnabled: true,
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
