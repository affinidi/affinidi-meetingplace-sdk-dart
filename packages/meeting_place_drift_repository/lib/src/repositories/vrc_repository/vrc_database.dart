import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../database/database_platform.dart';

part 'vrc_database.g.dart';

/// Drift database for persisting VRCs.
@DriftDatabase(tables: [Vrcs])
class VrcDatabase extends _$VrcDatabase {
  /// Constructs a [VrcDatabase] instance.
  VrcDatabase({
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

  /// Opens a [VrcDatabase] from an existing [connection].
  @visibleForTesting
  VrcDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;
}

/// Drift table representing VRCs.
@DataClassName('VrcRow')
class Vrcs extends Table {
  /// Stable credential identifier used as the primary key.
  TextColumn get id => text()();

  /// Raw serialized VC JSON string.
  TextColumn get vcBlob => text()();

  /// Channel identifier used as reference by the consumer app.
  TextColumn get referenceId => text()();

  /// DID of the credential holder.
  TextColumn get holderDid => text()();

  /// DID of the credential issuer.
  TextColumn get issuerDid => text()();

  /// Credential issuance timestamp.
  DateTimeColumn get issuedAt => dateTime()();

  /// Optional verification timestamp.
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  /// Optional receipt timestamp.
  DateTimeColumn get receivedAt => dateTime().nullable()();

  /// Optional credential format metadata.
  TextColumn get credentialFormat => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
