import 'package:json_annotation/json_annotation.dart';

part 'message_reaction.g.dart';

/// A single reaction applied to a chat message by one participant.
///
/// Reactions are owned: the same [emoji] from two different [senderDid]s are
/// two distinct reactions (rendered as a count), while the same [emoji] from
/// the same [senderDid] is a single reaction that toggles off when repeated.
@JsonSerializable()
class MessageReaction {
  const MessageReaction({required this.emoji, required this.senderDid});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);

  /// The emoji or symbol applied to the message.
  final String emoji;

  /// DID of the participant who applied this reaction.
  final String senderDid;

  Map<String, dynamic> toJson() => _$MessageReactionToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageReaction &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          senderDid == other.senderDid;

  @override
  int get hashCode => Object.hash(emoji, senderDid);
}
