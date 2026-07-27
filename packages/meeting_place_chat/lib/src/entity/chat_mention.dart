import 'package:json_annotation/json_annotation.dart';

part 'chat_mention.g.dart';

@JsonSerializable(includeIfNull: false)
class ChatMention {
  const ChatMention({
    required this.target,
    required this.start,
    required this.length,
    this.display,
    this.isRoomMention = false,
  });

  factory ChatMention.fromJson(Map<String, dynamic> json) {
    return _$ChatMentionFromJson(json);
  }

  final String target;
  final int start;
  final int length;
  final String? display;
  final bool isRoomMention;

  Map<String, dynamic> toJson() => _$ChatMentionToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMention &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          start == other.start &&
          length == other.length &&
          display == other.display &&
          isRoomMention == other.isRoomMention;

  @override
  int get hashCode =>
      Object.hash(target, start, length, display, isRoomMention);
}
