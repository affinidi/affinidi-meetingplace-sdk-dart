import 'dart:io';

import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

import 'utils/vrc_schema_versions.dart/schema.dart';

VrcDatabase _freshDatabase() => VrcDatabase(
  databaseName: 'vrc_migration_test.db',
  passphrase: 'test-passphrase',
  directory: Directory.systemTemp,
  inMemory: true,
);

void main() {
  test('schema snapshot exists for current schemaVersion', () {
    final db = _freshDatabase();
    expect(GeneratedHelper.versions, contains(db.schemaVersion));
    db.close();
  });
}
