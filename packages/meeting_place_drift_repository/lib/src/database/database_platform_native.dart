import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Class with implementations specific to native platforms
class DatabasePlatform {
  static NativeDatabase _openDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) {
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

  /// Creates a database for native platform using SQLite and SQLCipher.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [directory]: The directory where the database file is stored.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - A [QueryExecutor] instance connected to the encrypted database.
  static Future<QueryExecutor> createDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) async {
    return _openDatabase(
      databaseName: databaseName,
      passphrase: passphrase,
      directory: directory,
      logStatements: logStatements,
    );
  }

  static NativeDatabase _openInMemoryDatabase({
    required String passphrase,
    bool logStatements = false,
  }) {
    final sqliteDb = sqlite3.openInMemory();
    sqliteDb.execute("PRAGMA key = '$passphrase';");

    return NativeDatabase.opened(sqliteDb, logStatements: logStatements);
  }

  /// Creates an in-memory database for native platform using SQLite and
  /// SQLCipher.
  ///
  /// **Parameters:**
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - A [QueryExecutor] instance connected to the encrypted in-memory
  /// database.
  static Future<QueryExecutor> createInMemoryDatabase({
    required String passphrase,
    bool logStatements = false,
  }) async {
    return _openInMemoryDatabase(
      passphrase: passphrase,
      logStatements: logStatements,
    );
  }

  /// Information about the database platform.
  ///
  /// **Returns:**
  /// - A map containing platform and database type.
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
/// - [lazy]: When `true` (default), wraps the connection in a [LazyDatabase]
/// that defers opening until the first query. When `false`, opens the
/// database immediately and returns the executor directly.
///
/// **Returns:**
/// - A [QueryExecutor] — either a [LazyDatabase] or a ready-to-use executor.
QueryExecutor openConnection({
  required String databaseName,
  required String passphrase,
  required Directory directory,
  bool logStatements = false,
  bool inMemory = false,
  bool lazy = true,
}) {
  if (!lazy) {
    if (inMemory) {
      return DatabasePlatform._openInMemoryDatabase(
        passphrase: passphrase,
        logStatements: logStatements,
      );
    }
    return DatabasePlatform._openDatabase(
      databaseName: databaseName,
      passphrase: passphrase,
      directory: directory,
      logStatements: logStatements,
    );
  }

  if (inMemory) {
    return LazyDatabase(() async {
      return DatabasePlatform._openInMemoryDatabase(
        passphrase: passphrase,
        logStatements: logStatements,
      );
    });
  }

  return LazyDatabase(() async {
    return DatabasePlatform._openDatabase(
      databaseName: databaseName,
      passphrase: passphrase,
      directory: directory,
      logStatements: logStatements,
    );
  });
}
