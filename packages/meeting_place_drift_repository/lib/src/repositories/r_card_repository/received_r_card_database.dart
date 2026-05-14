import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../database/database_platform.dart';

part 'received_r_card_database.g.dart';

/// Drift database for persisting [ReceivedRCards] — the local store for
/// R-Cards received from contacts.
///
/// Uses the same encrypted [openConnection] setup as every other SDK
/// database.  Pass this instance to `ReceivedRCardRepositoryDrift` and
/// inject the repository into `MeetingPlaceRelationshipSDK`.
@DriftDatabase(tables: [ReceivedRCards])
class ReceivedRCardDatabase extends _$ReceivedRCardDatabase {
  /// Constructs a [ReceivedRCardDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file on disk.
  /// - [passphrase]: Passphrase used to encrypt the database via SQLCipher.
  /// - [directory]: Directory where the database file is stored.
  /// - [logStatements]: Whether to log SQL statements (default `false`).
  /// - [inMemory]: When `true` the database is held in memory only —
  ///   useful for tests (default `false`).
  ReceivedRCardDatabase({
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

  /// Opens a [ReceivedRCardDatabase] from an existing [connection].
  ///
  /// Intended for migration and schema verification tests only.
  @visibleForTesting
  ReceivedRCardDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;
}

/// Drift table representing received R-Cards.
///
/// Each row is keyed on [subjectDid] — the DID of the credential subject.
/// When a contact sends an updated R-Card the row is replaced in place and
/// [version] is incremented.
@DataClassName('ReceivedRCardRow')
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

  /// UTC issuance date taken from the VC's `validFrom` field.
  DateTimeColumn get issuanceDate => dateTime()();

  /// Optional user-supplied notes about this contact.
  TextColumn get notes => text().nullable()();

  /// Optional DIDComm thread ID associated with the R-Card exchange.
  TextColumn get threadId => text().nullable()();

  /// Permanent channel DID of the contact who sent this R-Card.
  TextColumn get contactChannelDid => text().nullable()();

  /// Our own local permanent channel DID for the channel this R-Card arrived
  /// on.  Set only for the OOB / inauguration path; `null` for the VDIP path.
  TextColumn get localChannelDid => text().nullable()();

  /// UTC timestamp recording when the R-Card was first received locally.
  DateTimeColumn get receivedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {subjectDid};
}
