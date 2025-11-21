import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database_platform.dart';

part 'identity_database.g.dart';

@DataClassName('IdentityRecord')
class Identities extends Table {
  TextColumn get id => text().clientDefault(const Uuid().v4)();
  TextColumn get did => text()();
  TextColumn get displayName => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get profilePic => text().nullable()();
  TextColumn get cardColor => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
        {did},
      ];
}

@DriftDatabase(tables: [Identities])
class IdentityDatabase extends _$IdentityDatabase {
  IdentityDatabase({
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
  @override
  int get schemaVersion => 1;
}
