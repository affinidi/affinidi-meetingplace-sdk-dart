import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/utils/cached_did_resolver.dart';

import 'sdk.dart';

String _sanitize(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
}

Future<matrix.Client> loginMatrixClient({
  required DidManager didManager,
}) async {
  final didDocument = await didManager.getDidDocument();
  final matrixConfig = getMatrixConfig();
  final controlPlaneSDK = ControlPlaneSDK(
    didManager: didManager,
    controlPlaneDid: getControlPlaneDid(),
    mediatorDid: getMediatorDid(),
    didResolver: CachedDidResolver(
      logger: DefaultMeetingPlaceCoreSDKLogger(),
    ),
  );
  final matrixTokenOutput = await controlPlaneSDK.execute(
    MatrixTokenCommand(
      didManager: didManager,
      homeserver: matrixConfig.homeserver,
    ),
  );
  final databaseName = 'meeting_place_core_example_'
      '${_sanitize(matrixConfig.homeserver.toString())}_'
      '${_sanitize(didDocument.id)}';
  final database = await matrix.MatrixSdkDatabase.init(
    databaseName,
    database: await matrixConfig.databaseFactory.openDatabase(
      MatrixDatabaseContext(
        userScope: didDocument.id,
        homeserver: matrixConfig.homeserver,
        databaseName: databaseName,
      ),
    ),
  );
  final client = matrix.Client(
    'meeting_place_core_example_${_sanitize(didDocument.id)}',
    database: database,
  );
  await client.checkHomeserver(
    matrixConfig.homeserver,
    checkWellKnown: false,
  );
  await client.login(
    'org.matrix.login.jwt',
    token: matrixTokenOutput.token.toJwt(),
  );
  await client.oneShotSync(timeout: Duration.zero);
  return client;
}

Future<void> sendMatrixTextMessage({
  required DidManager didManager,
  required String roomId,
  required String message,
}) async {
  final client = await loginMatrixClient(didManager: didManager);
  final room = client.getRoomById(roomId);
  if (room == null) {
    throw StateError('Room $roomId is not available after Matrix sync');
  }
  await room.sendTextEvent(message);
}
