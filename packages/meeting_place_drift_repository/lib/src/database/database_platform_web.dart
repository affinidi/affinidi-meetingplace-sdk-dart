import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Class with implementations specific to web platforms.
class DatabasePlatform {
  /// A static method to create a database for web platform using WASM
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database.
  ///
  /// **Returns:**
  /// - A [Future] that resolves to a [QueryExecutor] for the created database.
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

  /// A static method to create an in-memory database for web platform using
  /// WASM.
  ///
  /// **Returns:**
  /// - A [Future] that resolves to a [QueryExecutor] for the created in-memory
  /// database.
  static Future<QueryExecutor> createInMemoryDatabase() async {
    final result = await WasmDatabase.open(
      databaseName: ':memory:',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }

  /// Gets the current platform info.
  ///
  /// **Returns:**
  /// - A [Map] containing platform information.
  static Map<String, String> get info {
    return {'platform': 'web', 'database': 'IndexedDB'};
  }
}
