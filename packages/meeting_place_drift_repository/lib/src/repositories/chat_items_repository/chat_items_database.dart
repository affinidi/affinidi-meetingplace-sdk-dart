import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../database/database_platform.dart';

part 'chat_items_database.g.dart';

/// [ChatItemsDatabase] defines the Drift (SQLite) schema and
/// provides access to tables for chat items, reactions,
/// attachments, and attachment links.
///
/// It uses:
/// - [ChatItems] for storing message and concierge metadata.
/// - [Reactions] for tracking per-message reactions.
/// - [Attachments] for storing media or file attachments.
/// - [AttachmentsLinks] for external links tied to attachments.
///
/// Foreign key constraints are enabled via
/// `PRAGMA foreign_keys = ON` to ensure cascade deletes.
@DriftDatabase(tables: [ChatItems, Reactions, Attachments, AttachmentsLinks])

/// Opens or creates the database.
///
/// **Parameters:**
/// - databaseName: Logical name of the database file.
/// - passphrase: Optional encryption passphrase.
/// - directory: File location for storing the database.
/// - logStatements: Whether to log executed SQL (default: `false`).
class ChatItemsDatabase extends _$ChatItemsDatabase {
  /// Constructs a [ChatItemsDatabase] instance.
  ///
  /// **Parameters:**
  /// - [databaseName]: The name of the database file.
  /// - [passphrase]: The passphrase used to encrypt the database.
  /// - [directory]: The directory where the database file is stored.
  /// - [logStatements]: A boolean indicating whether to log SQL statements
  /// (default is false).
  ///
  /// **Returns:**
  /// - An instance of [ChatItemsDatabase].
  ChatItemsDatabase({
    required String databaseName,
    required String passphrase,
    required Directory directory,
    bool logStatements = false,
    bool inMemory = false,
    bool lazy = true,
  }) : super(
          openConnection(
            databaseName: databaseName,
            passphrase: passphrase,
            directory: directory,
            logStatements: logStatements,
            inMemory: inMemory,
            lazy: lazy,
          ),
        );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // SQLite does not support changing column types in-place.
            // Recreate chat_items with event_type and concierge_type as TEXT,
            // converting the old integer values to their string equivalents.
            //
            // Drop any leftover chat_items_new first so the migration is
            // idempotent: if a previous upgrade attempt was interrupted and
            // left a partial table behind, we start clean on retry.
            await customStatement(
              'DROP TABLE IF EXISTS chat_items_temp',
            );
            await customStatement('''
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
            // Explicit destination column list keeps the INSERT correct
            // regardless of column order changes in future schema versions.
            // Unknown legacy integer values are preserved as 'unknown:<n>'
            // rather than NULL so that corrupted rows remain diagnosable and
            // do not cause null-assert failures in the mapper.
            await customStatement('''
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
            await customStatement('DROP TABLE chat_items');
            await customStatement(
              'ALTER TABLE chat_items_temp RENAME TO chat_items',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Stores core metadata for messages and concierge items.
///
/// Primary key: [messageId].
@DataClassName('ChatItem')
class ChatItems extends Table {
  /// The chat ID this item belongs to.
  TextColumn get chatId => text()();

  /// Unique identifier for the chat item.
  TextColumn get messageId => text()();

  /// The main content of the chat item.
  TextColumn get value => text().nullable()();

  /// Indicates if the item was sent by the local user.
  BoolColumn get isFromMe => boolean().withDefault(const Constant(false))();

  /// Timestamp when the item was created.
  DateTimeColumn get dateCreated => dateTime().clientDefault(clock.now)();

  /// Status of the chat item.
  IntColumn get status => integer().map(const _ChatItemStatusConverter())();

  /// Type of the chat item.
  IntColumn get type => integer().map(const _ChatItemTypeConverter())();

  /// Event message type, if applicable.
  TextColumn get eventType => text().nullable()();

  /// Concierge message type, if applicable.
  TextColumn get conciergeType => text().nullable()();

  /// Additional data for concierge messages.
  TextColumn get data =>
      text().nullable().map(const _ConciergeDataConverter())();

  /// DID of the sender.
  TextColumn get senderDid => text()();

  /// Table primary key definition.
  @override
  Set<Column> get primaryKey => {messageId};
}

/// Stores reactions (emoji, likes, etc.) linked to a [ChatItem].
@DataClassName('Reaction')
class Reactions extends Table {
  /// The message ID this reaction is associated with.
  TextColumn get messageId => text().customConstraint(
        'REFERENCES chat_items(message_id) ON DELETE CASCADE NOT NULL',
      )();

  /// The reaction value (e.g., emoji).
  TextColumn get value => text()();
}

/// Stores file or media attachments tied to a [ChatItem].
@DataClassName('Attachment')
class Attachments extends Table {
  /// The message ID this attachment is associated with.
  TextColumn get messageId => text().customConstraint(
        'REFERENCES chat_items(message_id) ON DELETE CASCADE NOT NULL',
      )();

  /// Auto-incrementing unique identifier for the attachment.
  IntColumn get attachmentId => integer().autoIncrement()();

  /// Unique identifier for the attachment.
  TextColumn get id => text().nullable()();

  /// Description of the attachment.
  TextColumn get description => text().nullable()();

  /// Filename of the attachment.
  TextColumn get filename => text().nullable()();

  /// MIME type of the attachment.
  TextColumn get mediaType => text().nullable()();

  /// Format of the attachment.
  TextColumn get format => text().nullable()();

  /// Last modified time of the attachment.
  DateTimeColumn get lastModifiedTime => dateTime().nullable()();

  /// jws of the attachment.
  TextColumn get jws => text().nullable()();

  /// Size in bytes of the attachment.
  IntColumn get byteCount => integer().nullable()();

  /// Hash of the attachment.
  TextColumn get hash => text().nullable()();

  /// Base64 representation of the attachment.
  TextColumn get base64 => text().nullable()();

  /// JSON metadata of the attachment.
  TextColumn get json => text().nullable()();
}

/// Stores external links tied to an [Attachment].
@DataClassName('AttachmentLink')
class AttachmentsLinks extends Table {
  /// The attachment ID this link is associated with.
  IntColumn get attachmentId => integer().customConstraint(
        'REFERENCES attachments(attachment_id) ON DELETE CASCADE NOT NULL',
      )();

  /// The URL of the attachment link.
  TextColumn get url => text().map(const _UriConverter())();
}

extension _ChatItemStatusValue on ChatItemStatus {
  int get value {
    switch (this) {
      case ChatItemStatus.queued:
        return 1;
      case ChatItemStatus.sent:
        return 2;
      case ChatItemStatus.delivered:
        return 3;
      case ChatItemStatus.received:
        return 4;
      case ChatItemStatus.userInput:
        return 5;
      case ChatItemStatus.error:
        return 6;
      case ChatItemStatus.confirmed:
        return 7;
    }
  }
}

class _ChatItemStatusConverter extends TypeConverter<ChatItemStatus, int> {
  const _ChatItemStatusConverter();

  @override
  ChatItemStatus fromSql(int fromDb) {
    return ChatItemStatus.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ChatItemStatus value) {
    return value.value;
  }
}

extension _ChatItemTypeValue on ChatItemType {
  int get value {
    switch (this) {
      case ChatItemType.message:
        return 1;
      case ChatItemType.conciergeMessage:
        return 2;
      case ChatItemType.eventMessage:
        return 3;
    }
  }
}

class _ChatItemTypeConverter extends TypeConverter<ChatItemType, int> {
  const _ChatItemTypeConverter();

  @override
  ChatItemType fromSql(int fromDb) {
    return ChatItemType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ChatItemType value) {
    return value.value;
  }
}

class _ConciergeDataConverter
    extends TypeConverter<Map<String, dynamic>, String> {
  const _ConciergeDataConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return jsonDecode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

class _UriConverter extends TypeConverter<Uri, String> {
  const _UriConverter();

  @override
  Uri fromSql(String fromDb) {
    return Uri.parse(fromDb);
  }

  @override
  String toSql(Uri value) {
    return value.toString();
  }
}
