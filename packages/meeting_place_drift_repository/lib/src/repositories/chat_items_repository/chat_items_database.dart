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

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
  IntColumn get eventType =>
      integer().nullable().map(const _EventMessageTypeConverter())();

  /// Concierge message type, if applicable.
  IntColumn get conciergeType =>
      integer().nullable().map(const _ConciergeMessageTypeConverter())();

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

extension _EventMessageTypeValue on EventMessageType {
  int get value {
    switch (this) {
      case EventMessageType.groupMemberJoinedGroup:
        return 1;
      case EventMessageType.groupMemberLeftGroup:
        return 2;
      case EventMessageType.awaitingGroupMemberToJoin:
        return 3;
      case EventMessageType.groupDeleted:
        return 4;
      case EventMessageType.vrcExchangeInitiated:
        return 5;
      case EventMessageType.vrcRequestReceived:
        return 6;
      case EventMessageType.vrcExchangeDoLater:
        return 7;
      case EventMessageType.vrcExchangeCompleted:
        return 8;
      case EventMessageType.rCardPlaceholder:
        return 9;
    }
  }
}

class _EventMessageTypeConverter extends TypeConverter<EventMessageType, int> {
  const _EventMessageTypeConverter();

  @override
  EventMessageType fromSql(int fromDb) {
    return EventMessageType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(EventMessageType value) {
    return value.value;
  }
}

extension _ConciergeMessageTypeValue on ConciergeMessageType {
  int get value {
    switch (this) {
      case ConciergeMessageType.permissionToUpdateProfile:
        return 1;
      case ConciergeMessageType.permissionToJoinGroup:
        return 2;
      case ConciergeMessageType.permissionToVerifyRelationship:
        return 3;
    }
  }
}

class _ConciergeMessageTypeConverter
    extends TypeConverter<ConciergeMessageType, int> {
  const _ConciergeMessageTypeConverter();

  @override
  ConciergeMessageType fromSql(int fromDb) {
    return ConciergeMessageType.values.firstWhere(
      (type) => type.value == fromDb,
    );
  }

  @override
  int toSql(ConciergeMessageType value) {
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
