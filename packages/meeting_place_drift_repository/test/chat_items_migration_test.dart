import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

import 'utils/schema_versions.dart/schema.dart';

ChatItemsDatabase _freshDatabase() => ChatItemsDatabase(
  databaseName: 'migration_test.db',
  passphrase: 'test-passphrase',
  directory: Directory.systemTemp,
  inMemory: true,
  lazy: false,
);

// Queries a single nullable string column from chat_items via the Drift
// database (available after migrateAndValidate and before close).
Future<String?> _field(
  ChatItemsDatabase db,
  String messageId,
  String column,
) async {
  final rows = await db
      .customSelect(
        'SELECT $column FROM chat_items WHERE message_id = ?',
        variables: [Variable(messageId)],
      )
      .get();
  return rows.isEmpty ? null : rows.first.read<String?>(column);
}

void main() {
  // SchemaVerifier uses the generated snapshots in `drift_schemas/` and
  // exercises the actual ChatItemsDatabase.onUpgrade callback,
  // not hand-rolled SQL. When a v3 schema is added, only a new snapshot
  // file and a matching test block are needed; existing tests do not change.
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Canary: fails immediately in CI when schemaVersion is bumped without
  // running `drift_dev schema dump` + `drift_dev schema generate`.
  // See README - Schema Migrations for the required commands.
  test('schema snapshot exists for current schemaVersion', () {
    final db = _freshDatabase();
    expect(GeneratedHelper.versions, contains(db.schemaVersion));
    db.close();
  });

  group('v1 → v2 schema migration', () {
    test('produces the correct v2 schema', () async {
      final connection = await verifier.startAt(1);
      final db = ChatItemsDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, 2);
      await db.close();
    });

    test('converts integer type columns to their string equivalents', () async {
      // Use the v1 snapshot to create a real Drift-generated v1 database,
      // then seed it with representative rows before migrating.
      //
      // status: 4 = received, 5 = userInput
      // type:   2 = conciergeMessage, 3 = eventMessage
      // event_type integers: 1=groupMemberJoinedGroup, 2=groupMemberLeftGroup,
      //   3=awaitingGroupMemberToJoin, 4=groupDeleted, 99=unknown
      // concierge_type integers: 1=permissionToUpdateProfile,
      //   2=permissionToJoinGroup, 99=unknown
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute('''
        INSERT INTO chat_items VALUES
          ('c1','evt-joined','',0,'2026-01-01T00:00:00.000',4,3,1,NULL,NULL,'did:x:a'),
          ('c1','evt-left',  '',0,'2026-01-01T00:00:00.000',4,3,2,NULL,NULL,'did:x:a'),
          ('c1','evt-await', '',0,'2026-01-01T00:00:00.000',4,3,3,NULL,NULL,'did:x:a'),
          ('c1','evt-del',   '',0,'2026-01-01T00:00:00.000',4,3,4,NULL,NULL,'did:x:a'),
          ('c1','evt-null',  '',0,'2026-01-01T00:00:00.000',4,3,NULL,NULL,NULL,'did:x:a'),
          ('c1','evt-unk',   '',0,'2026-01-01T00:00:00.000',4,3,99,NULL,NULL,'did:x:a'),
          ('c1','con-prof',  '',0,'2026-01-01T00:00:00.000',5,2,NULL,1,'{}','did:x:a'),
          ('c1','con-grp',   '',0,'2026-01-01T00:00:00.000',5,2,NULL,2,'{}','did:x:a'),
          ('c1','con-null',  '',0,'2026-01-01T00:00:00.000',5,2,NULL,NULL,NULL,'did:x:a'),
          ('c1','con-unk',   '',0,'2026-01-01T00:00:00.000',5,2,NULL,99,'{}','did:x:a')
      ''');

      final db = ChatItemsDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);

      // Verify integer → string conversion via the live Drift connection.
      expect(
        await _field(db, 'evt-joined', 'event_type'),
        equals('groupMemberJoinedGroup'),
      );
      expect(
        await _field(db, 'evt-left', 'event_type'),
        equals('groupMemberLeftGroup'),
      );
      expect(
        await _field(db, 'evt-await', 'event_type'),
        equals('awaitingGroupMemberToJoin'),
      );
      expect(await _field(db, 'evt-del', 'event_type'), equals('groupDeleted'));
      expect(await _field(db, 'evt-null', 'event_type'), isNull);
      expect(await _field(db, 'evt-unk', 'event_type'), equals('unknown:99'));
      expect(
        await _field(db, 'con-prof', 'concierge_type'),
        equals('permissionToUpdateProfile'),
      );
      expect(
        await _field(db, 'con-grp', 'concierge_type'),
        equals('permissionToJoinGroup'),
      );
      expect(await _field(db, 'con-null', 'concierge_type'), isNull);
      expect(
        await _field(db, 'con-unk', 'concierge_type'),
        equals('unknown:99'),
      );

      final count =
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM chat_items')
                  .getSingle())
              .read<int>('n');
      expect(count, equals(10));

      await db.close();
    });
  });

  group('ChatItemsDatabase fresh v2 schema via repository', () {
    late ChatItemsDatabase db;
    late ChatItemsRepositoryDrift repository;

    setUp(() {
      db = _freshDatabase();
      repository = ChatItemsRepositoryDrift(database: db);
    });

    tearDown(() => db.close());

    test(
      'EventMessage with string type round-trips through v2 schema',
      () async {
        final message = EventMessage(
          chatId: 'c1',
          messageId: 'e1',
          senderDid: 'did:x:a',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.received,
          eventType: EventMessageType.groupMemberJoinedGroup,
          data: {},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'c1',
          messageId: 'e1',
        );

        expect(stored, isA<EventMessage>());
        expect(
          (stored! as EventMessage).eventType,
          equals(EventMessageType.groupMemberJoinedGroup),
        );
      },
    );

    test(
      'ConciergeMessage with string type round-trips through v2 schema',
      () async {
        final message = ConciergeMessage(
          chatId: 'c1',
          messageId: 'cm1',
          senderDid: 'did:x:a',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: ConciergeMessageType.permissionToJoinGroup,
          data: {'groupId': 'g1'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'c1',
          messageId: 'cm1',
        );

        expect(stored, isA<ConciergeMessage>());
        expect(
          (stored! as ConciergeMessage).conciergeType,
          equals(ConciergeMessageType.permissionToJoinGroup),
        );
      },
    );
  });

  group('v5 → v6 schema migration', () {
    test(
      'succeeds when attachments.metadata already exists (idempotency)',
      () async {
        // Reproduces the real device state: a v5 database whose attachments
        // table already has the metadata column from an intermediate build,
        // while user_version is still 5. Pre-fix this threw:
        //   SqliteException(1): duplicate column name: metadata
        final schema = await verifier.schemaAt(5);
        schema.rawDatabase.execute(
          'ALTER TABLE attachments ADD COLUMN metadata TEXT',
        );

        final db = ChatItemsDatabase.forTesting(schema.newConnection());
        // Any query triggers the lazy onUpgrade(5 → 6). Should not throw.
        final rows = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM attachments WHERE metadata IS NULL',
            )
            .get();
        expect(rows.single.read<int>('n'), 0);
        await db.close();
      },
    );
  });
}
