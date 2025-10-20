import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatAliasProfileRequest extends PlainTextMessage {
  ChatAliasProfileRequest({
    required super.id,
    required super.from,
    required super.to,
    required String profileHash,
  }) : super(
          type: Uri.parse(ChatProtocol.chatAliasProfileRequest.value),
          body: {'profileHash': profileHash},
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatAliasProfileRequest.create({
    required String from,
    required List<String> to,
    required String profileHash,
  }) {
    return ChatAliasProfileRequest(
      id: const Uuid().v4(),
      from: from,
      to: to,
      profileHash: profileHash,
    );
  }
}
