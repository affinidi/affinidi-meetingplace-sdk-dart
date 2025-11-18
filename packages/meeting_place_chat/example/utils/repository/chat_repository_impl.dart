import 'dart:convert';

import 'package:meeting_place_chat/src/entity/chat_item.dart';
import 'package:meeting_place_chat/src/entity/concierge_message.dart';
import 'package:meeting_place_chat/src/entity/message.dart';
import 'package:meeting_place_chat/src/repository/chat_repository.dart';

import '../storage.dart';

/// Implementation of [ChatRepository] that persists chat messages
/// using the provided [InMemoryStorage] backend.
///
/// Each message is stored under a key with the format:
/// `chat_<chatId>_<messageId>`.
class ChatRepositoryImpl implements ChatRepository {
  /// Creates a new [ChatRepositoryImpl] with the given [InMemoryStorage].
  ChatRepositoryImpl({required InMemoryStorage storage}) : _storage = storage;

  /// Prefix used for message keys in storage.
  static final String prefix = 'chat_';
  final InMemoryStorage _storage;

  /// Persists a new chat message into storage.
  ///
  /// **Parameters:**
  /// - [message]: The [ChatItem] instance containing the message data to
  /// be saved.
  ///
  /// **Returns:**
  /// - The same [ChatItem] after it has been stored.
  @override
  Future<ChatItem> createMessage(ChatItem message) async {
    await _storage.put(
      '$prefix${message.chatId}_${message.messageId}',
      json.encode(message.toJson()),
    );

    return message;
  }

  /// Updates an existing chat message in storage.
  ///
  /// **Parameters:**
  /// - [message]: The [ChatItem] instance containing the updated message data.
  ///
  /// **Returns:**
  /// - The updated [ChatItem] after being saved.
  @override
  Future<ChatItem> updateMesssage(ChatItem message) async {
    await _storage.put(
      '$prefix${message.chatId}_${message.messageId}',
      json.encode(message.toJson()),
    );

    return message;
  }

  /// Retrieves all messages associated with a chat.
  ///
  /// **Parameters:**
  /// - [chatId]: The unique identifier of the chat whose messages should be
  ///  listed.
  ///
  /// **Returns:**
  /// - A [List] of [ChatItem] objects decoded from storage.
  ///   Each entry is deserialized into either a [ConciergeMessage]
  ///  or [Message],
  ///   depending on the stored `type` field.
  @override
  Future<List<ChatItem>> listMessages(String chatId) async {
    final messages = await _storage.getCollection<MapEntry<String, dynamic>>(
      '$prefix$chatId',
    );

    final list = <ChatItem>[];
    for (final message in messages) {
      final decoded =
          json.decode(message.value as String) as Map<String, dynamic>;

      if (decoded['type'] == ChatItemType.conciergeMessage.name) {
        list.add(
          ConciergeMessage.fromJson(
            json.decode(message.value as String) as Map<String, dynamic>,
          ),
        );
      } else {
        list.add(
          Message.fromJson(
            json.decode(message.value as String) as Map<String, dynamic>,
          ),
        );
      }
    }

    return list;
  }

  /// Retrieves a single message by its identifiers.
  ///
  /// **Parameters:**
  /// - [chatId]: The unique identifier of the chat the message belongs to.
  /// - [messageId]: The unique identifier of the message within the chat.
  ///
  /// **Returns:**
  /// - A [ChatItem] if the message exists in storage,
  ///   or `null` if no matching entry is found.
  @override
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  }) async {
    final key = '$prefix${chatId}_$messageId';
    final message = await _storage.get<String>(key);
    return message != null
        ? Message.fromJson(jsonDecode(message) as Map<String, dynamic>)
        : null;
  }
}
