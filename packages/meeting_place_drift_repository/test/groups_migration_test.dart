import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

import 'utils/groups_schema_versions.dart/schema.dart';

GroupsDatabase _freshDatabase() => GroupsDatabase(
  databaseName: 'groups_migration_test.db',
  passphrase: 'test-passphrase',
  directory: Directory.systemTemp,
  inMemory: true,
);

Future<String?> _field(
  GroupsDatabase db,
  String groupId,
  String memberDid,
  String column,
) async {
  final rows = await db
      .customSelect(
        'SELECT $column FROM group_members'
        ' WHERE group_id = ? AND member_did = ?',
        variables: [Variable(groupId), Variable(memberDid)],
      )
      .get();
  return rows.isEmpty ? null : rows.first.read<String?>(column);
}

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Canary: fails immediately in CI when schemaVersion is bumped without
  // running `dart run drift_dev schema dump` + `drift_dev schema generate`.
  test('schema snapshot exists for current schemaVersion', () {
    final db = _freshDatabase();
    expect(GeneratedHelper.versions, contains(db.schemaVersion));
    db.close();
  });

  group('v1 → v2 schema migration', () {
    test('produces the correct v2 schema', () async {
      final connection = await verifier.startAt(1);
      final db = GroupsDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 2);
      await db.close();
    });

    test('converts individual contact columns to contact_info_json', () async {
      final schema = await verifier.schemaAt(1);

      schema.rawDatabase.execute('''
        INSERT INTO meeting_place_groups VALUES (
          'grp-1',
          'did:example:group',
          'offer-link-1',
          1,
          '2026-01-01T00:00:00.000',
          NULL,
          NULL,
          NULL
        )
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO group_members VALUES (
          'grp-1',
          'did:example:alice',
          NULL,
          NULL,
          NULL,
          NULL,
          '2026-01-02T00:00:00.000',
          'public-key',
          1,
          NULL,
          1,
          'did:example:identity',
          'Person',
          'Alice',
          'Jones',
          'alice@example.com',
          '+1-555-0100',
          'mxc://server/alice-pic',
          '#FF0000'
        )
      ''');

      final db = GroupsDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);

      final json = await _field(
        db,
        'grp-1',
        'did:example:alice',
        'contact_info_json',
      );
      expect(json, isNotNull);
      expect(json, contains('Alice'));
      expect(json, contains('Jones'));
      expect(json, contains('alice@example.com'));

      // profile_pic should have been preserved from the old non-null column.
      final pic = await _field(db, 'grp-1', 'did:example:alice', 'profile_pic');
      expect(pic, equals('mxc://server/alice-pic'));

      await db.close();
    });
    group('v2 → v3 schema migration', () {
      test('produces the correct v3 schema', () async {
        final connection = await verifier.startAt(2);
        final db = GroupsDatabase.forTesting(connection);
        await verifier.migrateAndValidate(db, 3);
        await db.close();
      });

      test('drops the public_key column', () async {
        final schema = await verifier.schemaAt(2);

        schema.rawDatabase.execute('''
        INSERT INTO meeting_place_groups VALUES (
          'grp-2',
          'did:example:group',
          'offer-link-2',
          1,
          '2026-01-01T00:00:00.000',
          NULL,
          NULL,
          NULL
        )
      ''');
        schema.rawDatabase.execute('''
        INSERT INTO group_members VALUES (
          'grp-2',
          'did:example:bob',
          NULL,
          NULL,
          NULL,
          NULL,
          '2026-01-02T00:00:00.000',
          'old-public-key',
          1,
          NULL,
          1,
          'did:example:identity',
          'Person',
          '{"n":{"given":"Bob"}}',
          NULL
        )
      ''');

        final db = GroupsDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(db, 3);

        // public_key column should be gone; querying it should fail.
        expect(
          () => db
              .customSelect(
                'SELECT public_key FROM group_members WHERE group_id = ?',
                variables: [const Variable('grp-2')],
              )
              .get(),
          throwsA(anything),
        );

        await db.close();
      });
    });
  });
}
