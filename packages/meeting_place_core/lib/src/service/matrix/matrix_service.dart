import "dart:convert";

import "package:crypto/crypto.dart";
import "package:matrix/matrix.dart" as matrix;

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

  Future<String> register({
    required String permanentChannelDid,
    required String deviceId,
  }) async {
    final hashedUsername = md5
        .convert(utf8.encode(permanentChannelDid))
        .toString();
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

  Future<String> createRoomForGroup() async {
    final roomId = await _matrixClient.createRoom();
    await _matrixClient.setRoomStateWithKey(roomId, 'm.room.join_rules', '', {
      'join_rule': matrix.JoinRules.knock.text,
    });

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
}
