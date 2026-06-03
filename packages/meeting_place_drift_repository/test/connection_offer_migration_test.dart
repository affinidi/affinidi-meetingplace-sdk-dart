import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

import 'utils/connection_offer_schema_versions.dart/schema.dart';

ConnectionOfferDatabase _freshDatabase() => ConnectionOfferDatabase(
  databaseName: 'connection_offer_migration_test.db',
  passphrase: 'test-passphrase',
  directory: Directory.systemTemp,
  inMemory: true,
);

Future<String?> _field(
  ConnectionOfferDatabase db,
  String connectionOfferId,
  String column,
) async {
  final rows = await db
      .customSelect(
        'SELECT $column FROM connection_contact_cards'
        ' WHERE connection_offer_id = ?',
        variables: [Variable(connectionOfferId)],
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
      final db = ConnectionOfferDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 2);
      await db.close();
    });

    test('converts individual contact columns to contact_info_json', () async {
      final schema = await verifier.schemaAt(1);

      schema.rawDatabase.execute("""
        INSERT INTO connection_offers VALUES (
          'offer-1',
          'Offer Name',
          'https://example.com/offer',
          NULL,
          'oob-msg',
          'mnemonic words',
          NULL,
          '2026-01-01T00:00:00.000',
          'did:example:publisher',
          1,
          1,
          NULL,
          0,
          'did:example:mediator',
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL
        )
      """);
      schema.rawDatabase.execute("""
        INSERT INTO connection_contact_cards VALUES (
          1,
          'offer-1',
          'did:example:alice',
          'Person',
          'Alice',
          'Jones',
          'alice@example.com',
          '+1-555-0100',
          'mxc://server/alice-pic',
          '#FF0000'
        )
      """);

      final db = ConnectionOfferDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);

      final json = await _field(db, 'offer-1', 'contact_info_json');
      expect(json, isNotNull);
      expect(json, contains('Alice'));
      expect(json, contains('Jones'));
      expect(json, contains('alice@example.com'));

      // profile_pic is preserved from the old non-null column.
      final pic = await _field(db, 'offer-1', 'profile_pic');
      expect(pic, equals('mxc://server/alice-pic'));

      await db.close();
    });
  });

  group('v2 → v3 schema migration', () {
    test('produces the correct v3 schema', () async {
      final connection = await verifier.startAt(2);
      final db = ConnectionOfferDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 3);
      await db.close();
    });

    test('adds nullable score column, existing rows default to null', () async {
      final schema = await verifier.schemaAt(2);

      schema.rawDatabase.execute("""
        INSERT INTO connection_offers VALUES (
          'offer-v2',
          'Offer Name',
          'https://example.com/offer',
          NULL,
          'oob-msg',
          'mnemonic words',
          NULL,
          '2026-01-01T00:00:00.000',
          'did:example:publisher',
          1,
          1,
          NULL,
          0,
          'did:example:mediator',
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL
        )
      """);

      final db = ConnectionOfferDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      final rows = await db
          .customSelect(
            'SELECT score FROM connection_offers WHERE id = ?',
            variables: [const Variable('offer-v2')],
          )
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.read<int?>('score'), isNull);

      await db.close();
    });
  });
}
