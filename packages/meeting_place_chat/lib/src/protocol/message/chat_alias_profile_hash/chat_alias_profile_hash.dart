import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_alias_profile_hash_body.dart';

class ChatAliasProfileHash {
  factory ChatAliasProfileHash.create({
    required String from,
    required List<String> to,
    required String profileHash,
  }) {
    return ChatAliasProfileHash(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatAliasProfileHashBody(profileHash: profileHash),
    );
  }

  factory ChatAliasProfileHash.fromPlainTextMessage(PlainTextMessage message) {
    return ChatAliasProfileHash(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatAliasProfileHashBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatAliasProfileHash({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatAliasProfileHashBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatAliasProfileHash.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
