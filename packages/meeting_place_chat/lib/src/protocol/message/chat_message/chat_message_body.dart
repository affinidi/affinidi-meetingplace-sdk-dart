import 'package:json_annotation/json_annotation.dart';

part 'chat_message_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChatMessageBody {
  factory ChatMessageBody.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageBodyFromJson(json);

  ChatMessageBody({
    required this.text,
    required this.seqNo,
    required this.timestamp,
  });

  @JsonKey(name: 'text')
  final String text;

  @JsonKey(name: 'seq_no')
  final int seqNo;

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$ChatMessageBodyToJson(this);
}
