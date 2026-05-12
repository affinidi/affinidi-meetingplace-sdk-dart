import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

import 'utils/channel_schema_versions.dart/schema.dart';

ChannelDatabase _freshDatabase() => ChannelDatabase(
      databaseName: 'channel_migration_test.db',
      passphrase: 'test-passphrase',
      directory: Directory.systemTemp,
      inMemory: true,
    );

Future<String?> _field(
  ChannelDatabase db,
  String channelId,
  int cardType,
  String column,
) async {
  final rows = await db.customSelect(
    'SELECT $column FROM channel_contact_cards'
    ' WHERE channel_id = ? AND card_type = ?',
    variables: [Variable(channelId), Variable(cardType)],
  ).get();
  return rows.isEmpty ? null : rows.first.read<String?>(column);
}

void main() {
  // SchemaVerifier uses the generated snapshots in `drift_schemas/channel/`
  // and exercises the actual ChannelDatabase.onUpgrade callback.
  // When a v4 schema is added, only a new snapshot file + test block are
  // needed; existing tests do not change.
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Canary: fails immediately in CI when schemaVersion is bumped without
  // running `dart run drift_dev schema dump` + `drift_dev schema generate`.
  // See README – Schema Migrations for the required commands.
  test('schema snapshot exists for current schemaVersion', () {
    final db = _freshDatabase();
    expect(GeneratedHelper.versions, contains(db.schemaVersion));
    db.close();
  });

  group('v1 → v2 schema migration', () {
    test('produces the correct v2 schema', () async {
      final connection = await verifier.startAt(1);
      final db = ChannelDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 2);
      await db.close();
    });

    test('adds is_connection_initiator and converts contact columns to JSON',
        () async {
      final schema = await verifier.schemaAt(1);

      // Seed a channel row and a contact card with the old individual columns.
      schema.rawDatabase.execute('''
        INSERT INTO channels VALUES (
          'ch-1',
          'did:example:publisher',
          'did:example:mediator',
          'offer-link-1',
          1,
          1,
          NULL,
          NULL,
          'did:example:permanent',
          NULL,
          NULL,
          NULL,
          NULL,
          0,
          NULL
        )
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO channel_contact_cards VALUES (
          1,
          'ch-1',
          'did:example:alice',
          'Person',
          'Alice',
          'Jones',
          'alice@example.com',
          '+1-555-0100',
          'mxc://server/alice-pic',
          '#FF0000',
          1
        )
      ''');

      final db = ChannelDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);

      // is_connection_initiator must exist with its default value of 0.
      final rows = await db.customSelect(
        'SELECT is_connection_initiator FROM channels WHERE id = ?',
        variables: [const Variable('ch-1')],
      ).get();
      expect(rows.single.read<int>('is_connection_initiator'), equals(0));

      // contact_info_json must contain the data from the old columns.
      final json = await _field(db, 'ch-1', 1, 'contact_info_json');
      expect(json, isNotNull);
      expect(json, contains('Alice'));
      expect(json, contains('Jones'));
      expect(json, contains('alice@example.com'));
      expect(json, contains('mxc://server/alice-pic'));

      await db.close();
    });
  });

  group('v2 → v3 schema migration', () {
    test('produces the correct v3 schema', () async {
      final connection = await verifier.startAt(2);
      final db = ChannelDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 3);
      await db.close();
    });

    test('adds profile_pic column with NULL as default', () async {
      final schema = await verifier.schemaAt(2);

      schema.rawDatabase.execute('''
        INSERT INTO channels VALUES (
          'ch-2',
          'did:example:publisher',
          'did:example:mediator',
          'offer-link-2',
          1,
          1,
          0,
          NULL,
          NULL,
          'did:example:permanent2',
          NULL,
          NULL,
          NULL,
          NULL,
          0,
          NULL
        )
      ''');
      schema.rawDatabase.execute('''
        INSERT INTO channel_contact_cards VALUES (
          1,
          'ch-2',
          'did:example:bob',
          'Person',
          '{"n":{"given":"Bob","surname":"Smith"}}',
          1
        )
      ''');

      final db = ChannelDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      // profile_pic must exist and default to NULL for existing rows.
      final profilePic = await _field(db, 'ch-2', 1, 'profile_pic');
      expect(profilePic, isNull);

      await db.close();
    });
  });

  group('v3 → v4 schema migration', () {
    test('produces the correct v4 schema', () async {
      final connection = await verifier.startAt(3);
      final db = ChannelDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 4);
      await db.close();
    });

    test('adds matrix_room_id column with NULL as default', () async {
      final schema = await verifier.schemaAt(3);

      schema.rawDatabase.execute('''
        INSERT INTO channels VALUES (
          'ch-3',
          'did:example:publisher',
          'did:example:mediator',
          'offer-link-3',
          1,
          1,
          0,
          NULL,
          NULL,
          'did:example:permanent3',
          NULL,
          NULL,
          NULL,
          NULL,
          0,
          NULL
        )
      ''');

      final db = ChannelDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);

      // matrix_room_id must exist and default to NULL for existing rows.
      final rows = await db.customSelect(
        'SELECT matrix_room_id FROM channels WHERE id = ?',
        variables: [const Variable('ch-3')],
      ).get();
      expect(rows.single.read<String?>('matrix_room_id'), isNull);

      await db.close();
    });
  });
}
