import 'package:drift/drift.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart' as model;
import 'package:synchronized/synchronized.dart';

import '../../../meeting_place_drift_repository.dart';
import '../../exceptions/meeting_place_core_repository_error_code.dart';
import 'chat_items_database.dart' as db;

/// [ChatItemsRepositoryDrift] is a Drift (SQLite)–backed implementation
/// of [model.ChatRepository].
///
/// It handles **CRUD operations** for chat items, including:
/// - Persisting [model.Message]s and [model.ConciergeMessage]s
/// - Managing **reactions** linked to messages
/// - Storing **attachments** and their associated links
/// - Fetching chat items by ID or listing all items in a chat
///
/// Internally, it maps between the database schema (`db.*` entities)
/// and SDK models (`model.*` entities).
class ChatItemsRepositoryDrift implements model.ChatRepository {
  /// Creates a new repository using the given Drift [database].
  ChatItemsRepositoryDrift({required db.ChatItemsDatabase database})
      : _database = database;

  final db.ChatItemsDatabase _database;

  late final _createMessageLock = Lock();
  late final _updateMessageLock = Lock();

  /// Persists a [model.Message] to the database, including its
  /// reactions and attachments. Skips if the message already exists.
  Future<model.Message> _createMessage(model.Message message) async {
    late model.ChatItem addedEntry;

    await _createMessageLock.synchronized(() async {
      final exitingMessage = await getMessage(
        chatId: message.chatId,
        messageId: message.messageId,
      );
      if (exitingMessage != null) {
        addedEntry = exitingMessage;
        return addedEntry as model.Message;
      }

      await _database.transaction(() async {
        await _database.into(_database.chatItems).insert(
              db.ChatItemsCompanion(
                chatId: Value(message.chatId),
                messageId: Value(message.messageId),
                value: Value(message.value),
                isFromMe: Value(message.isFromMe),
                dateCreated: Value(message.dateCreated),
                status: Value(message.status),
                type: Value(message.type),
                senderDid: Value(message.senderDid),
                data: Value(message.data),
              ),
            );
        final newMessage = await (_database.select(_database.chatItems)
              ..where((filter) => filter.messageId.equals(message.messageId)))
            .getSingleOrNull();
        if (newMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        final reactionCompanions = message.reactions.map((reaction) {
          return db.ReactionsCompanion.insert(
            messageId: message.messageId,
            value: reaction,
          );
        }).toList();

        await _database.batch((batch) {
          batch.insertAll(_database.reactions, reactionCompanions);
        });

        for (final attachment in message.attachments) {
          final attachmentId =
              await _database.into(_database.attachments).insert(
                    db.AttachmentsCompanion.insert(
                      messageId: message.messageId,
                      id: Value(attachment.id),
                      description: Value(attachment.description),
                      filename: Value(attachment.filename),
                      mediaType: Value(attachment.mediaType),
                      format: Value(attachment.format),
                      lastModifiedTime: Value(attachment.lastModifiedTime),
                      jws: Value(attachment.data?.jws),
                      byteCount: Value(attachment.byteCount),
                      hash: Value(attachment.data?.hash),
                      base64: Value(attachment.data?.base64),
                      json: Value(attachment.data?.json),
                    ),
                  );
          for (final link in (attachment.data?.links ?? <Uri>[])) {
            await _database.into(_database.attachmentsLinks).insert(
                  db.AttachmentsLinksCompanion.insert(
                    attachmentId: attachmentId,
                    url: link,
                  ),
                );
          }
        }

        final addedMessage = await getMessage(
          chatId: message.chatId,
          messageId: message.messageId,
        );
        if (addedMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        addedEntry = addedMessage;
      });
    });

    return addedEntry as model.Message;
  }

  /// Persists a [model.ConciergeMessage] to the database.
  Future<model.ConciergeMessage> _createConciergeMessage(
    model.ConciergeMessage message,
  ) async {
    late model.ChatItem addedEntry;
    await _createMessageLock.synchronized(() async {
      final exitingMessage = await getMessage(
        chatId: message.chatId,
        messageId: message.messageId,
      );
      if (exitingMessage != null) {
        addedEntry = exitingMessage;
        return addedEntry as model.ConciergeMessage;
      }

      await _database.transaction(() async {
        await _database.into(_database.chatItems).insert(
              db.ChatItemsCompanion(
                chatId: Value(message.chatId),
                messageId: Value(message.messageId),
                isFromMe: Value(message.isFromMe),
                dateCreated: Value(message.dateCreated),
                status: Value(message.status),
                type: Value(message.type),
                conciergeType: Value(message.conciergeType),
                data: Value(message.data),
                senderDid: Value(message.senderDid),
              ),
            );

        final newMessage = await (_database.select(_database.chatItems)
              ..where((filter) => filter.messageId.equals(message.messageId)))
            .getSingleOrNull();
        if (newMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        addedEntry = _ChatItemMapper.fromDatabaseRecords(newMessage, [], {});
      });
    });
    return addedEntry as model.ConciergeMessage;
  }

  Future<model.EventMessage> _createEventMessage(
    model.EventMessage message,
  ) async {
    late model.ChatItem addedEntry;
    await _createMessageLock.synchronized(() async {
      final exitingMessage = await getMessage(
        chatId: message.chatId,
        messageId: message.messageId,
      );
      if (exitingMessage != null) {
        addedEntry = exitingMessage;
        return addedEntry as model.EventMessage;
      }

      await _database.transaction(() async {
        await _database.into(_database.chatItems).insert(
              db.ChatItemsCompanion(
                chatId: Value(message.chatId),
                messageId: Value(message.messageId),
                isFromMe: Value(message.isFromMe),
                dateCreated: Value(message.dateCreated),
                status: Value(message.status),
                type: Value(message.type),
                eventType: Value(message.eventType),
                data: Value(message.data),
                senderDid: Value(message.senderDid),
              ),
            );

        final newMessage = await (_database.select(_database.chatItems)
              ..where((filter) => filter.messageId.equals(message.messageId)))
            .getSingleOrNull();
        if (newMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        addedEntry = _ChatItemMapper.fromDatabaseRecords(newMessage, [], {});
      });
    });

    return addedEntry as model.EventMessage;
  }

  /// Creates a new chat item in the database.
  ///
  /// Supports both [model.Message] and [model.ConciergeMessage].
  /// Throws [MeetingPlaceCoreRepositoryException] if the type is unsupported.
  @override
  Future<model.ChatItem> createMessage(model.ChatItem message) async {
    if (message is model.Message) {
      return _createMessage(message);
    }

    if (message is model.ConciergeMessage) {
      return _createConciergeMessage(message);
    }

    if (message is model.EventMessage) {
      return _createEventMessage(message);
    }

    throw MeetingPlaceCoreRepositoryException(
      'Unsupported message type',
      code: MeetingPlaceCoreRepositoryErrorCode.unsupportedMessageType,
    );
  }

  /// Retrieves a chat item by [chatId] and [messageId].
  ///
  /// Loads associated **reactions** and **attachments with links**
  /// before returning the result.
  ///
  /// **Returns:**
  /// - The matching [model.ChatItem], or `null` if not found.
  @override
  Future<model.ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  }) async {
    final message = await (_database.select(_database.chatItems)
          ..where(
            (m) => m.chatId.equals(chatId) & m.messageId.equals(messageId),
          ))
        .getSingleOrNull();

    if (message == null) return null;

    final results = await Future.wait([
      (_database.select(
        _database.reactions,
      )..where((r) => r.messageId.equals(messageId)))
          .get(),
      _groupAttachmentsWithLinksByChatItem([message.messageId]),
    ]);

    final reactions = results[0] as List<db.Reaction>;
    final attachmentsWithLinksByChatItem =
        results[1] as Map<String, Map<db.Attachment, List<db.AttachmentLink>>>;

    return _ChatItemMapper.fromDatabaseRecords(
      message,
      reactions,
      attachmentsWithLinksByChatItem[message.messageId] ?? {},
    );
  }

  /// Lists all chat items in the given [chatId].
  ///
  /// Includes **reactions** and **attachments with links**.
  @override
  Future<List<model.ChatItem>> listMessages(String chatId) async {
    final chatItems = await (_database.select(
      _database.chatItems,
    )..where((m) => m.chatId.equals(chatId)))
        .get();
    final messageIds = chatItems.map((c) => c.messageId);

    final results = await Future.wait([
      (_database.select(
        _database.reactions,
      )..where((r) => r.messageId.isIn(messageIds)))
          .get(),
      _groupAttachmentsWithLinksByChatItem(messageIds.toList()),
    ]);

    final reactions = results[0] as List<db.Reaction>;
    final reactionsByMessages = <String, List<db.Reaction>>{};
    for (final r in reactions) {
      reactionsByMessages.putIfAbsent(r.messageId, () => []).add(r);
    }

    final attachmentsWithLinksByChatItem =
        results[1] as Map<String, Map<db.Attachment, List<db.AttachmentLink>>>;

    return chatItems
        .map(
          (m) => _ChatItemMapper.fromDatabaseRecords(
            m,
            reactionsByMessages[m.messageId] ?? [],
            attachmentsWithLinksByChatItem[m.messageId] ?? {},
          ),
        )
        .toList();
  }

  /// Updates an existing [model.Message], replacing its
  /// reactions and attachments with the latest state.
  Future<model.Message> _updateMessage(model.Message message) async {
    late model.ChatItem updatedEntry;
    await _updateMessageLock.synchronized(() async {
      await _database.transaction(() async {
        await (_database.update(
          _database.chatItems,
        )..where((m) => m.messageId.equals(message.messageId)))
            .write(
          db.ChatItemsCompanion(
            chatId: Value(message.chatId),
            messageId: Value(message.messageId),
            value: Value(message.value),
            isFromMe: Value(message.isFromMe),
            dateCreated: Value(message.dateCreated),
            status: Value(message.status),
            type: Value(message.type),
            senderDid: Value(message.senderDid),
            data: Value(message.data),
          ),
        );

        await (_database.delete(
          _database.reactions,
        )..where((a) => a.messageId.equals(message.messageId)))
            .go();

        final reactionCompanions = message.reactions.map((reaction) {
          return db.ReactionsCompanion.insert(
            messageId: message.messageId,
            value: reaction,
          );
        }).toList();

        await _database.batch((batch) {
          batch.insertAll(_database.reactions, reactionCompanions);
        });

        await (_database.delete(
          _database.attachments,
        )..where((a) => a.messageId.equals(message.messageId)))
            .go();

        for (final attachment in message.attachments) {
          final attachmentId =
              await _database.into(_database.attachments).insert(
                    db.AttachmentsCompanion.insert(
                      messageId: message.messageId,
                      id: Value(attachment.id),
                      description: Value(attachment.description),
                      filename: Value(attachment.filename),
                      mediaType: Value(attachment.mediaType),
                      format: Value(attachment.format),
                      lastModifiedTime: Value(attachment.lastModifiedTime),
                      jws: Value(attachment.data?.jws),
                      byteCount: Value(attachment.byteCount),
                      hash: Value(attachment.data?.hash),
                      base64: Value(attachment.data?.base64),
                      json: Value(attachment.data?.json),
                    ),
                  );
          for (final link in (attachment.data?.links ?? <Uri>[])) {
            await _database.into(_database.attachmentsLinks).insert(
                  db.AttachmentsLinksCompanion.insert(
                    attachmentId: attachmentId,
                    url: link,
                  ),
                );
          }
        }

        final updatedMessage = await getMessage(
          chatId: message.chatId,
          messageId: message.messageId,
        );

        if (updatedMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        updatedEntry = updatedMessage;
      });
    });
    return updatedEntry as model.Message;
  }

  /// Updates an existing [model.ConciergeMessage].
  Future<model.ConciergeMessage> _updateConciergeMessage(
    model.ConciergeMessage message,
  ) async {
    late model.ChatItem updatedEntry;
    await _updateMessageLock.synchronized(() async {
      await _database.transaction(() async {
        await (_database.update(
          _database.chatItems,
        )..where((m) => m.messageId.equals(message.messageId)))
            .write(
          db.ChatItemsCompanion(
            chatId: Value(message.chatId),
            messageId: Value(message.messageId),
            isFromMe: Value(message.isFromMe),
            dateCreated: Value(message.dateCreated),
            status: Value(message.status),
            type: Value(message.type),
            conciergeType: Value(message.conciergeType),
            data: Value(message.data),
            senderDid: Value(message.senderDid),
          ),
        );

        final updatedMessage = await (_database.select(_database.chatItems)
              ..where(
                (m) =>
                    m.chatId.equals(message.chatId) &
                    m.messageId.equals(message.messageId),
              ))
            .getSingleOrNull();

        if (updatedMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        updatedEntry = _ChatItemMapper.fromDatabaseRecords(
          updatedMessage,
          [],
          {},
        );
      });
    });

    return updatedEntry as model.ConciergeMessage;
  }

  Future<model.EventMessage> _updateEventMessage(
    model.EventMessage message,
  ) async {
    late model.ChatItem updatedEntry;
    await _updateMessageLock.synchronized(() async {
      await _database.transaction(() async {
        await (_database.update(
          _database.chatItems,
        )..where((m) => m.messageId.equals(message.messageId)))
            .write(
          db.ChatItemsCompanion(
            chatId: Value(message.chatId),
            messageId: Value(message.messageId),
            isFromMe: Value(message.isFromMe),
            dateCreated: Value(message.dateCreated),
            status: Value(message.status),
            eventType: Value(message.eventType),
            type: Value(message.type),
            data: Value(message.data),
            senderDid: Value(message.senderDid),
          ),
        );

        final updatedMessage = await (_database.select(_database.chatItems)
              ..where(
                (m) =>
                    m.chatId.equals(message.chatId) &
                    m.messageId.equals(message.messageId),
              ))
            .getSingleOrNull();

        if (updatedMessage == null) {
          throw MeetingPlaceCoreRepositoryException(
            'Message not found',
            code: MeetingPlaceCoreRepositoryErrorCode.missingMessage,
          );
        }

        updatedEntry = _ChatItemMapper.fromDatabaseRecords(
          updatedMessage,
          [],
          {},
        );
      });
    });

    return updatedEntry as model.EventMessage;
  }

  /// Updates an existing chat item.
  ///
  /// Supports both [model.Message] and [model.ConciergeMessage].
  /// Throws [MeetingPlaceCoreRepositoryException] if the type is unsupported.
  @override
  Future<model.ChatItem> updateMessage(model.ChatItem message) async {
    if (message is model.Message) {
      return _updateMessage(message);
    }

    if (message is model.ConciergeMessage) {
      return _updateConciergeMessage(message);
    }

    if (message is model.EventMessage) {
      return _updateEventMessage(message);
    }

    throw MeetingPlaceCoreRepositoryException(
      'Unsupported message type',
      code: MeetingPlaceCoreRepositoryErrorCode.unsupportedMessageType,
    );
  }

  /// Groups attachments and their associated links by message ID.
  ///
  /// **Returns:**
  /// - A map where each key is a `messageId`, and the value
  ///   is a mapping of attachments : their links.
  Future<Map<String, Map<db.Attachment, List<db.AttachmentLink>>>>
      _groupAttachmentsWithLinksByChatItem(List<String> messageIds) async {
    final attachments = await (_database.select(
      _database.attachments,
    )..where((a) => a.messageId.isIn(messageIds)))
        .get();
    final attachmentIds = attachments.map((a) => a.attachmentId);
    final attachmentLinks = await (_database.select(
      _database.attachmentsLinks,
    )..where((l) => l.attachmentId.isIn(attachmentIds)))
        .get();

    final attachmentByMessages = <String, List<db.Attachment>>{};
    for (final a in attachments) {
      attachmentByMessages.putIfAbsent(a.messageId, () => []).add(a);
    }

    final linksByAttachments = <int, List<db.AttachmentLink>>{};
    for (final l in attachmentLinks) {
      linksByAttachments.putIfAbsent(l.attachmentId, () => []).add(l);
    }

    final attachmentsWithLinksByMessage = Map.fromEntries(
      messageIds.map((m) {
        final attachmentsByMessage = attachmentByMessages[m] ?? [];

        final attachmentsWithLinksByMessage = Map.fromEntries(
          attachmentsByMessage.map(
            (a) => MapEntry(a, linksByAttachments[a.attachmentId] ?? []),
          ),
        );
        return MapEntry(m, attachmentsWithLinksByMessage);
      }),
    );

    return attachmentsWithLinksByMessage;
  }
}

/// [_ChatItemMapper] provides mapping utilities between
/// Drift database records (`db.*`) and SDK models (`model.*`).
///
/// It converts low-level DB entities into high-level
/// [model.Message] and [model.ConciergeMessage] objects.
class _ChatItemMapper {
  static model.ChatItem fromDatabaseRecords(
    db.ChatItem message,
    List<db.Reaction> reactions,
    Map<db.Attachment, List<db.AttachmentLink>> attachments,
  ) {
    if (message.type == model.ChatItemType.message) {
      return model.Message(
        chatId: message.chatId,
        messageId: message.messageId,
        value: message.value!,
        isFromMe: message.isFromMe,
        dateCreated: message.dateCreated,
        status: message.status,
        reactions: reactions.map((r) => r.value).toList(),
        senderDid: message.senderDid,
        data: message.data,
        attachments: attachments.entries
            .map(
              (a) => model.Attachment(
                id: a.key.id,
                description: a.key.description,
                filename: a.key.filename,
                mediaType: a.key.mediaType,
                format: a.key.format,
                lastModifiedTime: a.key.lastModifiedTime,
                data: model.AttachmentData(
                  jws: a.key.jws,
                  hash: a.key.hash,
                  links: a.value.map((l) => l.url).toList(),
                  base64: a.key.base64,
                  json: a.key.json,
                ),
                byteCount: a.key.byteCount,
              ),
            )
            .toList(),
      );
    }

    if (message.type == model.ChatItemType.conciergeMessage) {
      return model.ConciergeMessage(
        chatId: message.chatId,
        messageId: message.messageId,
        senderDid: message.senderDid,
        isFromMe: message.isFromMe,
        dateCreated: message.dateCreated,
        status: message.status,
        data: message.data!,
        conciergeType: message.conciergeType!,
      );
    }

    if (message.type == model.ChatItemType.eventMessage) {
      return model.EventMessage(
        chatId: message.chatId,
        messageId: message.messageId,
        senderDid: message.senderDid,
        eventType: message.eventType!,
        isFromMe: message.isFromMe,
        dateCreated: message.dateCreated,
        status: message.status,
        data: message.data!,
      );
    }

    throw MeetingPlaceCoreRepositoryException(
      'Unsupported message type',
      code: MeetingPlaceCoreRepositoryErrorCode.unsupportedMessageType,
    );
  }
}
