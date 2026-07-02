import 'package:matrix/matrix.dart' show DatabaseApi;
import 'package:meeting_place_core/meeting_place_core.dart';

class MatrixConfig extends Config {
  MatrixConfig({
    required super.mediatorDid,
    required super.controlPlaneDid,
    required this.homeserver,
    required this.databaseFactory,
    required this.deviceId,
    String? serverName,
    this.livekitServiceUrl,
    this.livekitSfuUrl,
    this.outgoingCallTimeout = const Duration(seconds: 10),
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

  /// URL of the lk-jwt-service that issues LiveKit JWTs. Required for
  /// audio/video calls; when omitted the call plugin is not created.
  final Uri? livekitServiceUrl;

  /// WebSocket URL of the LiveKit SFU. Overrides the URL from the token
  /// response — useful for local development where the container-internal
  /// hostname is not reachable from the device.
  final Uri? livekitSfuUrl;

  /// How long the caller waits for the remote party to answer before the
  /// call is automatically ended and reported as missed. Defaults to 10 s.
  final Duration outgoingCallTimeout;
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
