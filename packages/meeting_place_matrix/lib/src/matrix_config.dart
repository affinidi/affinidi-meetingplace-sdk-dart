import 'package:matrix/matrix.dart' show DatabaseApi;
import 'package:meeting_place_core/meeting_place_core.dart';

/// [MeetingPlaceCoreConfig] for a Matrix-backed `MeetingPlaceMatrixSDK`,
/// adding the Matrix homeserver, local database, and optional LiveKit
/// call settings.
class MatrixConfig extends MeetingPlaceCoreConfig {
  MatrixConfig({
    required super.mediatorDid,
    required super.controlPlaneDid,
    required this.homeserver,
    required this.databaseFactory,
    required this.deviceId,
    String? serverName,
    this.livekitServiceUrl,
    this.livekitSfuUrl,
    this.outgoingCallTimeout = const Duration(seconds: 60),
  }) : serverName = serverName ?? homeserver.host;

  /// URL of the Matrix homeserver to authenticate against.
  final Uri homeserver;

  /// Opens the local Matrix session/crypto database for this device.
  final MatrixDatabaseFactory databaseFactory;

  /// Stable identifier for this device's Matrix session.
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

  /// How long the caller waits for the remote party to answer before the call
  /// is automatically ended and reported as missed.
  ///
  /// Defaults to 60 s so the timeout matches a real unanswered call instead
  /// of reporting a missed call while the callee is still deciding whether to
  /// answer.
  final Duration outgoingCallTimeout;
}

/// Identifies which local Matrix database a [MatrixDatabaseFactory] should
/// open or create.
class MatrixDatabaseContext {
  const MatrixDatabaseContext({
    required this.userScope,
    required this.homeserver,
    required this.databaseName,
  });

  /// Identifier for the local user/wallet the database belongs to, used to
  /// keep multiple accounts' databases isolated on the same device.
  final String userScope;

  /// The Matrix homeserver the session in this database is scoped to.
  final Uri homeserver;

  /// Name to give the underlying database file/store.
  final String databaseName;
}

/// Opens the local storage backing a Matrix client's session and crypto
/// state.
///
/// Implementations live in the consumer app layer, which decides how (or
/// whether) persistent storage is provisioned per platform.
abstract interface class MatrixDatabaseFactory {
  /// Opens the database identified by [context], or returns `null` to run
  /// the Matrix client without persistent storage.
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context);
}

/// [MatrixDatabaseFactory] that delegates to a caller-supplied callback.
class CallbackMatrixDatabaseFactory implements MatrixDatabaseFactory {
  const CallbackMatrixDatabaseFactory({
    required Future<DatabaseApi?> Function(MatrixDatabaseContext context)
    openDatabase,
  }) : _openDatabase = openDatabase;

  final Future<DatabaseApi?> Function(MatrixDatabaseContext context)
  _openDatabase;

  /// Forwards to the callback supplied at construction.
  @override
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context) {
    return _openDatabase(context);
  }
}

/// [MatrixDatabaseFactory] for consumers that have not configured a local
/// Matrix database; [openDatabase] always throws.
class UnsupportedMatrixDatabaseFactory implements MatrixDatabaseFactory {
  const UnsupportedMatrixDatabaseFactory({
    this.message =
        'Matrix database initialization is not configured for this consumer.',
  });

  /// Explanation included in the [UnsupportedError] thrown by [openDatabase].
  final String message;

  @override
  Future<DatabaseApi?> openDatabase(MatrixDatabaseContext context) {
    throw UnsupportedError(
      '$message userScope=${context.userScope}, '
      'databaseName=${context.databaseName}',
    );
  }
}
