import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_alias_profile_hash_body.dart';

class ChatAliasProfileHash extends PlainTextMessage {
  ChatAliasProfileHash({
    required super.id,
    required super.from,
    required super.to,
    required String profileHash,
  }) : super(
          type: Uri.parse(ChatProtocol.chatAliasProfileHash.value),
          body: ChatAliasProfileHashBody(profileHash: profileHash).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatAliasProfileHash.create({
    required String from,
    required List<String> to,
    required String profileHash,
  }) {
    return ChatAliasProfileHash(
      id: const Uuid().v4(),
      from: from,
      to: to,
      profileHash: profileHash,
    );
  }
}
