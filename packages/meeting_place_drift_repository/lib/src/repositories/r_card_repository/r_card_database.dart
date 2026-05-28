import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../database/database_platform.dart';

part 'r_card_database.g.dart';

/// Drift database for persisting [ReceivedRCards] — the local store for
/// R-Cards received from contacts.
///
/// Uses the same encrypted [openConnection] setup as every other SDK
/// database.  Pass this instance to `RCardRepositoryDrift` and
/// inject the repository into `MeetingPlaceRelationshipSDK`.
@DriftDatabase(tables: [ReceivedRCards])
class RCardDatabase extends _$RCardDatabase {
  /// Constructs a [RCardDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file on disk.
  /// - [passphrase]: Passphrase used to encrypt the database via SQLCipher.
  /// - [directory]: Directory where the database file is stored.
  /// - [logStatements]: Whether to log SQL statements (default `false`).
  /// - [inMemory]: When `true` the database is held in memory only —
  ///   useful for tests (default `false`).
  RCardDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
    bool inMemory = false,
  }) : super(
         openConnection(
           databaseName: databaseName,
           passphrase: passphrase,
           directory: directory,
           logStatements: logStatements,
           inMemory: inMemory,
         ),
       );

  /// Opens a [RCardDatabase] from an existing [connection].
  ///
  /// Intended for migration and schema verification tests only.
  @visibleForTesting
  RCardDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;
}

/// Drift table representing received R-Cards.
///
/// Each row is keyed on [subjectDid] — the DID of the credential subject.
/// When a contact sends an updated R-Card the row is replaced in place and
/// [version] is incremented.
@DataClassName('RCardRow')
class ReceivedRCards extends Table {
  /// DID of the credential subject — serves as the primary key.
  TextColumn get subjectDid => text()();

  /// Raw serialised VC JSON blob.
  TextColumn get vcBlob => text()();

  /// DID of the credential issuer.
  TextColumn get issuerDid => text()();

  /// Monotonically increasing version counter.  Starts at `1` and is
  /// incremented by the repository on every real (content-changing) upsert.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// UTC issuance timestamp from the VC, using DM v1 `issuanceDate`
  /// (with `validFrom` accepted as a fallback during parsing).
  DateTimeColumn get issuanceDate => dateTime()();

  /// Optional user-supplied notes about this contact.
  TextColumn get notes => text().nullable()();

  /// UTC timestamp recording when the R-Card was first received locally.
  DateTimeColumn get receivedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {subjectDid};
}
