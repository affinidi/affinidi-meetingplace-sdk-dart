import 'package:matrix/matrix.dart' as matrix;

import 'matrix_config.dart';

class MatrixClient {
  static final _clientName = 'meeting_place';

  static Future<matrix.Client> init({
    required MatrixConfig config,
    required String userScope,
  }) async {
    final context = _buildDatabaseContext(
      homeserver: config.homeserver,
      userScope: userScope,
    );
    final database = await matrix.MatrixSdkDatabase.init(
      context.databaseName,
      database: await config.databaseFactory.openDatabase(context),
    );

    final client = matrix.Client(
      '${_clientName}_$userScope',
      database: database,
    );

    // TODO: verify if we need to check well-known as well
    await client.checkHomeserver(config.homeserver, checkWellKnown: false);

    return client;
  }

  static MatrixDatabaseContext _buildDatabaseContext({
    required Uri homeserver,
    required String userScope,
  }) {
    final sanitizedHomeserver = homeserver
        .replace(query: null, fragment: null)
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .toLowerCase();

    final sanitizedUserScope = userScope
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .toLowerCase();

    return MatrixDatabaseContext(
      userScope: userScope,
      homeserver: homeserver,
      databaseName: '${_clientName}_${sanitizedHomeserver}_$sanitizedUserScope',
    );
  }
}
