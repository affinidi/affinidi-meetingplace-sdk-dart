import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_alias_profile_request_body.dart';

class ChatAliasProfileRequest {
  factory ChatAliasProfileRequest.create({
    required String from,
    required List<String> to,
    required String profileHash,
  }) {
    return ChatAliasProfileRequest(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChatAliasProfileRequestBody(profileHash: profileHash),
    );
  }

  factory ChatAliasProfileRequest.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return ChatAliasProfileRequest(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatAliasProfileRequestBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatAliasProfileRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatAliasProfileRequestBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatAliasProfileRequest.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
