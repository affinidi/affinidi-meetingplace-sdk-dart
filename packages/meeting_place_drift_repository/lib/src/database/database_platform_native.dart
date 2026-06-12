import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../exceptions/meeting_place_core_repository_error_code.dart';
import '../exceptions/meeting_place_core_repository_exception.dart';

/// Class with implementations specific to native platforms
class DatabasePlatform {
  static NativeDatabase _openDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
  }) {
    final dbPath = p.join(directory.path, databaseName);
    final escapedPassphrase = passphrase.replaceAll("'", "''");

    final sqliteDb = sqlite3.open(dbPath);

    // PRAGMA cipher is sqlite3mc-specific and replaces the old
    // PRAGMA cipher_version check that only worked with SQLCipher.
    final cipherCheck = sqliteDb.select('PRAGMA cipher;');
    if (cipherCheck.isEmpty) {
      sqliteDb.dispose();
      throw MeetingPlaceCoreRepositoryException(
        'Database encryption not available. '
        'Add to pubspec.yaml: '
        'hooks: user_defines: sqlite3: source: sqlite3mc',
        code: MeetingPlaceCoreRepositoryErrorCode.encryptionNotAvailable,
      );
    }

    // Try default sqlite3mc cipher first — used for new databases and
    // databases already created with the current sqlite3mc build.
    try {
      sqliteDb.execute("PRAGMA key = '$escapedPassphrase';");
      sqliteDb.select('SELECT count(*) FROM sqlite_master;');
      return NativeDatabase.opened(sqliteDb, logStatements: logStatements);
    } on SqliteException catch (e) {
      developer.log(
        'Default sqlite3mc cipher failed, retrying with SQLCipher '
        'legacy mode: $e',
        name: 'DatabasePlatform',
      );
      sqliteDb.dispose();
    }

    // Default cipher failed — database was created with SQLCipher.
    // Reopen in compatibility mode (legacy only for migration).
    final legacyDb = sqlite3.open(dbPath);
    try {
      legacyDb.execute("PRAGMA cipher = 'sqlcipher';");
      legacyDb.execute('PRAGMA legacy = 4;');
      legacyDb.execute("PRAGMA key = '$escapedPassphrase';");
      legacyDb.select('SELECT count(*) FROM sqlite_master;');
      return NativeDatabase.opened(legacyDb, logStatements: logStatements);
    } catch (e, st) {
      developer.log(
        'SQLCipher legacy mode failed: $e',
        name: 'DatabasePlatform',
        error: e,
        stackTrace: st,
      );
      legacyDb.dispose();
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
  /// In-memory databases do not use file-based encryption.
  ///
  /// **Parameters:**
  /// - [passphrase]: Accepted for API consistency with [createDatabase] but
  /// not applied to the in-memory database.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - A [QueryExecutor] instance connected to the in-memory database.
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
/// - [passphrase]: The passphrase used to open the encrypted database when
///   [inMemory] is `false`.
/// - [directory]: The directory where the database file is stored.
/// - [logStatements]: A boolean indicating whether to log SQL statements
/// (default is false).
/// - [inMemory]: When `true`, returns an in-memory database and skips
///   file-based encryption configuration.
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
    return DatabasePlatform.createDatabase(
      databaseName: databaseName,
      passphrase: passphrase,
      directory: directory,
      logStatements: logStatements,
    );
  });
}
