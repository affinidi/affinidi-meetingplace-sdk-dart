import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Class with implementations specific to web platform
class DatabasePlatform {
  /// Creates a database for web platform using WASM
  ///
  /// [databaseName] - The database name
  static Future<QueryExecutor> createDatabase({
    required String databaseName,
  }) async {
    final result = await WasmDatabase.open(
      databaseName: databaseName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }

  /// Creates an in-memory database for web platform using WASM
  static Future<QueryExecutor> createInMemoryDatabase() async {
    final result = await WasmDatabase.open(
      databaseName: ':memory:',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }

  /// Gets the current platform info
  static Map<String, String> get info {
    return {'platform': 'web', 'database': 'IndexedDB'};
  }
}
