import 'package:matrix/matrix.dart' as matrix;

class MatrixClient {
  static final _clientName = 'meeting_place';

  static Future<matrix.Client> init({
    required Uri homeserver,
    required String userScope,
    required Future<dynamic> Function(String) databaseProvider,
  }) async {
    final database = await matrix.MatrixSdkDatabase.init(
      _buildDatabaseName(homeserver: homeserver, userScope: userScope),
      database: await databaseProvider(userScope),
    );

    final client = matrix.Client(
      '${_clientName}_$userScope',
      database: database,
    );

    // TODO: verify if we need to check well-known as well
    await client.checkHomeserver(homeserver, checkWellKnown: false);

    return client;
  }

  static String _buildDatabaseName({
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

    return '${_clientName}_${sanitizedHomeserver}_$sanitizedUserScope';
  }
}
