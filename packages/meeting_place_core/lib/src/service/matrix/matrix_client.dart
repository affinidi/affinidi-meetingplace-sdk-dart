import 'package:matrix/matrix.dart' as matrix;
import 'package:vodozemac/vodozemac.dart' as vod;

import 'matrix_config.dart';

/// Factory for creating and managing Matrix client instances,
/// including database initialization and homeserver checks.
class MatrixClient {
  /// A base name for the Matrix client, used in database naming and client
  /// identification. The actual client name will be suffixed with the user
  /// scope and a sanitized version of the homeserver URI to ensure uniqueness.
  static final _clientName = 'meeting_place';

  /// Initializes a new Matrix client instance for the given [userScope] and
  /// [config]. This involves setting up the database context, initializing the
  /// database, and performing a homeserver check to ensure connectivity.
  ///
  /// Requires `vodozemac` to be initialized by the consumer before this method
  /// is invoked (see [_assertVodozemacInitialized]); otherwise the resulting
  /// Matrix client cannot encrypt or decrypt room events.
  ///
  /// Parameters:
  /// - [config]: The configuration for the Matrix client, including homeserver
  ///   URI and database factory.
  /// - [userScope]: A string representing the user scope, used to derive the
  ///   Matrix user ID and to namespace the database.
  ///
  /// Returns: A fully initialized and ready-to-use Matrix client instance.
  static Future<matrix.Client> init({
    required MatrixConfig config,
    required String userScope,
  }) async {
    _assertVodozemacInitialized();

    final context = _buildDatabaseContext(
      homeserver: config.homeserver,
      userScope: userScope,
    );
    final database =
        await config.databaseFactory.openDatabase(context) ??
        await matrix.MatrixSdkDatabase.init(context.databaseName);

    final client = matrix.Client(
      '${_clientName}_$userScope',
      database: database,
    );

    // TODO: verify if we need to check well-known as well
    await client.checkHomeserver(config.homeserver, checkWellKnown: false);

    return client;
  }

  static void _assertVodozemacInitialized() {
    if (vod.isInitialized()) return;
    throw StateError(
      'vodozemac is not initialized. Matrix end-to-end encryption requires '
      'the vodozemac native library to be loaded before the SDK creates a '
      'Matrix client.\n'
      '  Flutter apps: add `flutter_vodozemac` to your pubspec and call '
      '`await fvod.init()` once during app startup.\n'
      '  Pure-Dart apps: build vodozemac and call '
      '`await vod.init(libraryPath: ...)` from package:vodozemac before using '
      'the SDK.',
    );
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
