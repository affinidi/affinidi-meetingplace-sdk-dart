import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Class with implementations specific to native platforms
class DatabasePlatform {
  /// Creates a database for native platform using SQLite
  ///
  /// [databaseName] - The database name
  /// it is required on native
  static Future<QueryExecutor> createDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) async {
    final dbPath = p.join(directory.path, databaseName);

    final sqliteDb = sqlite3.open(dbPath);
    sqliteDb.execute("PRAGMA key = '$passphrase';");

    final cipherVersion = sqliteDb.select('PRAGMA cipher_version;');
    if (cipherVersion.isEmpty) {
      throw UnsupportedError('SQLCipher not available');
    }

    sqliteDb.select('SELECT count(*) FROM sqlite_master;');

    return NativeDatabase.opened(sqliteDb, logStatements: logStatements);
  }

  /// Creates an in-memory database for native platform using SQLite
  static Future<QueryExecutor> createInMemoryDatabase({
    required String passphrase,
    bool logStatements = false,
  }) async {
    final sqliteDb = sqlite3.openInMemory();
    sqliteDb.execute("PRAGMA key = '$passphrase';");

    return NativeDatabase.opened(sqliteDb, logStatements: logStatements);
  }

  /// Gets the current platform info
  static Map<String, String> get info {
    return {'platform': 'native', 'database': 'SQLite'};
  }
}

/// Opens a connection to the database using native platform implementation.
///
/// **Parameters:**
/// - [databaseName]: The name of the database file.
/// - [passphrase]: The passphrase used to encrypt the database.
/// - [directory]: The directory where the database file is stored.
/// - [logStatements]: A boolean indicating whether to log SQL statements
/// (default is false).
///
/// **Returns:**
/// - A [LazyDatabase] instance that opens the database connection when needed.
LazyDatabase openConnection({
  required String databaseName,
  required String passphrase,
  required Directory directory,
  bool logStatements = false,
}) {
  return LazyDatabase(() async {
    final database = await DatabasePlatform.createDatabase(
      databaseName: databaseName,
      passphrase: passphrase,
      directory: directory,
      logStatements: logStatements,
    );
    return database;
  });
}
