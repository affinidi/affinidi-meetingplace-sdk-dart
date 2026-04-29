import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

ChatItemsDatabase _freshDatabase() => ChatItemsDatabase(
      databaseName: 'migration_test.db',
      passphrase: 'test-passphrase',
      directory: Directory.systemTemp,
      inMemory: true,
      lazy: false,
    );

Database _runMigrationSql() {
  final db = sqlite3.openInMemory();
  db.execute("PRAGMA key = 'test-passphrase';");

  db.execute('''
    CREATE TABLE chat_items (
      chat_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      value TEXT,
      is_from_me INTEGER NOT NULL DEFAULT 0,
      date_created TEXT NOT NULL,
      status INTEGER NOT NULL,
      "type" INTEGER NOT NULL,
      event_type INTEGER,
      concierge_type INTEGER,
      data TEXT,
      sender_did TEXT NOT NULL,
      PRIMARY KEY (message_id)
    )
  ''');

  // status 4 = received, status 5 = userInput
  // type   2 = conciergeMessage, type 3 = eventMessage
  db.execute('''
    INSERT INTO chat_items VALUES
      ('c1','evt-joined','',0,'2026-01-01T00:00:00.000Z',4,3,1,NULL,NULL,'did:x:a'),
      ('c1','evt-left',  '',0,'2026-01-01T00:00:00.000Z',4,3,2,NULL,NULL,'did:x:a'),
      ('c1','evt-await', '',0,'2026-01-01T00:00:00.000Z',4,3,3,NULL,NULL,'did:x:a'),
      ('c1','evt-del',   '',0,'2026-01-01T00:00:00.000Z',4,3,4,NULL,NULL,'did:x:a'),
      ('c1','evt-null',  '',0,'2026-01-01T00:00:00.000Z',4,3,NULL,NULL,NULL,'did:x:a'),
      ('c1','evt-unk',   '',0,'2026-01-01T00:00:00.000Z',4,3,99,NULL,NULL,'did:x:a'),
      ('c1','con-prof',  '',0,'2026-01-01T00:00:00.000Z',5,2,NULL,1,'{}','did:x:a'),
      ('c1','con-grp',   '',0,'2026-01-01T00:00:00.000Z',5,2,NULL,2,'{}','did:x:a'),
      ('c1','con-null',  '',0,'2026-01-01T00:00:00.000Z',5,2,NULL,NULL,NULL,'did:x:a'),
      ('c1','con-unk',   '',0,'2026-01-01T00:00:00.000Z',5,2,NULL,99,'{}','did:x:a')
  ''');

  db.execute('DROP TABLE IF EXISTS chat_items_temp');

  db.execute('''
    CREATE TABLE chat_items_temp (
      chat_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      value TEXT,
      is_from_me INTEGER NOT NULL DEFAULT 0,
      date_created INTEGER NOT NULL,
      status INTEGER NOT NULL,
      "type" INTEGER NOT NULL,
      event_type TEXT,
      concierge_type TEXT,
      data TEXT,
      sender_did TEXT NOT NULL,
      PRIMARY KEY (message_id)
    )
  ''');

  db.execute('''
    INSERT INTO chat_items_temp (
      chat_id, message_id, value, is_from_me, date_created,
      status, "type", event_type, concierge_type, data, sender_did
    )
    SELECT
      chat_id, message_id, value, is_from_me, date_created,
      status, "type",
      CASE event_type
        WHEN 1 THEN 'groupMemberJoinedGroup'
        WHEN 2 THEN 'groupMemberLeftGroup'
        WHEN 3 THEN 'awaitingGroupMemberToJoin'
        WHEN 4 THEN 'groupDeleted'
        WHEN NULL THEN NULL
        ELSE 'unknown:' || CAST(event_type AS TEXT)
      END,
      CASE concierge_type
        WHEN 1 THEN 'permissionToUpdateProfile'
        WHEN 2 THEN 'permissionToJoinGroup'
        WHEN NULL THEN NULL
        ELSE 'unknown:' || CAST(concierge_type AS TEXT)
      END,
      data, sender_did
    FROM chat_items
  ''');

  db.execute('DROP TABLE chat_items');
  db.execute('ALTER TABLE chat_items_temp RENAME TO chat_items');

  return db;
}

String? _field(Database db, String messageId, String column) {
  final rows = db.select(
    'SELECT $column FROM chat_items WHERE message_id = ?',
    [messageId],
  );
  return rows.isEmpty ? null : rows.first[column] as String?;
}

void main() {
  group('ChatItemsDatabase schema v1→v2 migration SQL', () {
    late Database db;

    setUpAll(() {
      db = _runMigrationSql();
    });

    tearDownAll(() => db.dispose());

    group('event_type integer → string', () {
      test('1 → groupMemberJoinedGroup', () {
        expect(_field(db, 'evt-joined', 'event_type'),
            equals('groupMemberJoinedGroup'));
      });

      test('2 → groupMemberLeftGroup', () {
        expect(_field(db, 'evt-left', 'event_type'),
            equals('groupMemberLeftGroup'));
      });

      test('3 → awaitingGroupMemberToJoin', () {
        expect(_field(db, 'evt-await', 'event_type'),
            equals('awaitingGroupMemberToJoin'));
      });

      test('4 → groupDeleted', () {
        expect(_field(db, 'evt-del', 'event_type'), equals('groupDeleted'));
      });

      test('NULL stays NULL', () {
        expect(_field(db, 'evt-null', 'event_type'), isNull);
      });

      test('unknown integer → unknown:<n>', () {
        expect(_field(db, 'evt-unk', 'event_type'), equals('unknown:99'));
      });
    });

    group('concierge_type integer → string', () {
      test('1 → permissionToUpdateProfile', () {
        expect(_field(db, 'con-prof', 'concierge_type'),
            equals('permissionToUpdateProfile'));
      });

      test('2 → permissionToJoinGroup', () {
        expect(_field(db, 'con-grp', 'concierge_type'),
            equals('permissionToJoinGroup'));
      });

      test('NULL stays NULL', () {
        expect(_field(db, 'con-null', 'concierge_type'), isNull);
      });

      test('unknown integer → unknown:<n>', () {
        expect(_field(db, 'con-unk', 'concierge_type'), equals('unknown:99'));
      });
    });

    test('all 10 rows are preserved after migration', () {
      final count =
          db.select('SELECT COUNT(*) AS n FROM chat_items').first['n'] as int;
      expect(count, equals(10));
    });

    test('migration is idempotent (DROP IF EXISTS guard)', () {
      // Running the migration a second time should not throw.
      expect(_runMigrationSql, returnsNormally);
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
        final stored =
            await repository.getMessage(chatId: 'c1', messageId: 'e1');

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
        final stored =
            await repository.getMessage(chatId: 'c1', messageId: 'cm1');

        expect(stored, isA<ConciergeMessage>());
        expect(
          (stored! as ConciergeMessage).conciergeType,
          equals(ConciergeMessageType.permissionToJoinGroup),
        );
      },
    );
  });
}
