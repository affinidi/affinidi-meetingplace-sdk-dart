import 'package:matrix/matrix.dart' show DatabaseApi;
import '../config.dart';

class MatrixConfig extends Config {
  MatrixConfig({
    required super.mediatorDid,
    required super.controlPlaneDid,
    required this.homeserver,
    required this.databaseFactory,
    required this.deviceId,
    String? serverName,
  }) : serverName = serverName ?? homeserver.host;

  final Uri homeserver;
  final MatrixDatabaseFactory databaseFactory;
  final String deviceId;

  /// The Matrix server name used for user ID derivation (`@hash:<serverName>`).
  ///
  /// In production this equals [homeserver].host. For local development the
  /// homeserver may be reached via a tunnel (e.g. ngrok) whose hostname
  /// differs from the Synapse `server_name` — pass this field explicitly so
  /// all clients derive consistent user IDs regardless of which URL they use
  /// to connect.
  final String serverName;
}

class MatrixDatabaseContext {
  const MatrixDatabaseContext({
    required this.userScope,
    required this.homeserver,
    required this.databaseName,
  });

  final String userScope;
  final Uri homeserver;
  final String databaseName;
}

abstract interface class MatrixDatabaseFactory {
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context);
}

class CallbackMatrixDatabaseFactory implements MatrixDatabaseFactory {
  const CallbackMatrixDatabaseFactory({
    required Future<DatabaseApi?> Function(MatrixDatabaseContext context)
    openDatabase,
  }) : _openDatabase = openDatabase;

  final Future<DatabaseApi?> Function(MatrixDatabaseContext context)
  _openDatabase;

  @override
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context) {
    return _openDatabase(context);
  }
}

class UnsupportedMatrixDatabaseFactory implements MatrixDatabaseFactory {
  const UnsupportedMatrixDatabaseFactory({
    this.message =
        'Matrix database initialization is not configured for this consumer.',
  });

  final String message;

  @override
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context) {
    throw UnsupportedError(
      '$message userScope=${context.userScope}, '
      'databaseName=${context.databaseName}',
    );
  }
}
