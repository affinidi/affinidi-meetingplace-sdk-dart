import 'package:json_annotation/json_annotation.dart';

import '../../../../entity/chat_mention.dart';

part 'chat_message_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatMessageBody {
  factory ChatMessageBody.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageBodyFromJson(json);

  ChatMessageBody({
    required this.text,
    required this.seqNo,
    required this.timestamp,
    this.mentions = const [],
  });

  @JsonKey(name: 'text')
  final String text;

  @JsonKey(name: 'seq_no')
  final int seqNo;

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  @JsonKey(name: 'mentions')
  final List<ChatMention> mentions;

  Map<String, dynamic> toJson() => _$ChatMessageBodyToJson(this);
}
