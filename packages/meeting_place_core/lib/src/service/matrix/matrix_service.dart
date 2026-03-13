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

  // TODO: generate and persist password securely - this is just for testing
  static final String _passwordPlaceholder = 'dummy_password';
  static final String _authenticationType = 'm.login.dummy';

  static final String _logKey = 'MatrixService';

  get timelineEventStream => _matrixClient.onTimelineEvent.stream;

  Future<String> register({
    required String permanentChannelDid,
    required String deviceId,
  }) async {
    final hashedUsername = md5
        .convert(utf8.encode(permanentChannelDid))
        .toString();

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
      deviceId: deviceId,
      initialDeviceDisplayName: permanentChannelDid,
      auth: matrix.AuthenticationData(type: _authenticationType),
    );

    _logger?.info('''Device registered on MATRIX homeserver for
        DID: ${permanentChannelDid.topAndTail()}, using id
        ${response.userId.topAndTail()} and
        deviceId ${deviceId.topAndTail()}''', name: _logKey);

    return response.userId;
  }

  Future<String> login({required String did, required String deviceId}) async {
    final hashedUsername = md5.convert(utf8.encode(did)).toString();

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
      deviceId: deviceId,
    );

    return response.userId;
  }

  Future<String> createRoomForGroup() async {
    final roomId = await _matrixClient.createRoom();
    // await _matrixClient.setRoomStateWithKey(roomId, 'm.room.join_rules', '', {
    //   'join_rule': matrix.JoinRules.invite.text,
    // });

    _logger?.info(
      '''Created MATRIX room ${roomId.topAndTail()} for group''',
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

    _logger?.info(
      '''Joined MATRIX room ${roomId.topAndTail()}''',
      name: _logKey,
    );
  }

  Future<String> sendMessage({
    required String roomId,
    required String message,
  }) async {
    // await _matrixClient.sync(fullState: true);
    final eventId = await _matrixClient.sendMessage(
      roomId,
      'm.room.message',
      const Uuid().v4(),
      {"body": message, "msgtype": "m.text"},
    );

    _logger?.info('''Sent message with event id $eventId
      to MATRIX room ${roomId.topAndTail()}''', name: _logKey);

    return eventId;
  }
}
