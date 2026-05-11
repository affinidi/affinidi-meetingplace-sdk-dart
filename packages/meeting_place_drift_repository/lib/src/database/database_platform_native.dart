import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Class with implementations specific to native platforms
class DatabasePlatform {
  static void _configureEncryptedDatabase(
    Database sqliteDb,
    String passphrase,
  ) {
    sqliteDb.execute("PRAGMA cipher = 'sqlcipher';");
    sqliteDb.execute('PRAGMA legacy = 4;');
    final escapedPassphrase = passphrase.replaceAll("'", "''");
    sqliteDb.execute("PRAGMA key = '$escapedPassphrase';");

    final cipherVersion = sqliteDb.select('PRAGMA cipher_version;');
    if (cipherVersion.isEmpty) {
      throw UnsupportedError(
        'Database encryption support is not available. '
        'Ensure your app includes sqlcipher_flutter_libs as a dependency '
        'and that the native SQLite build supports SQLCipher or sqlite3mc. '
        'See: https://pub.dev/packages/sqlcipher_flutter_libs',
      );
    }
  }

  static NativeDatabase _openDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) {
    final dbPath = p.join(directory.path, databaseName);

    final sqliteDb = sqlite3.open(dbPath);
    try {
      _configureEncryptedDatabase(sqliteDb, passphrase);
      sqliteDb.select('SELECT count(*) FROM sqlite_master;');
      return NativeDatabase.opened(sqliteDb, logStatements: logStatements);
    } catch (_) {
      sqliteDb.close();
      rethrow;
    }
  }

  /// Creates a database for native platform using SQLite with encryption.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to open the encrypted database.
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

  static NativeDatabase _openInMemoryDatabase({bool logStatements = false}) {
    return NativeDatabase.memory(logStatements: logStatements);
  }

  /// Creates an in-memory database for native platform using SQLite.
  ///
  /// In-memory databases do not support encryption (sqlite3mc limitation), so
  /// encryption configuration is skipped.
  ///
  /// **Parameters:**
  /// - [passphrase]: Accepted for API consistency with [createDatabase] but
  /// not applied; in-memory databases are always unencrypted.
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
    return _openInMemoryDatabase(logStatements: logStatements);
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
/// - [passphrase]: The passphrase used to open the encrypted database.
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
