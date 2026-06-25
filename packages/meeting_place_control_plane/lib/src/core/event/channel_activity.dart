import 'package:json_annotation/json_annotation.dart';

part 'channel_activity.g.dart';

/// Notification event indicating that activity has occurred on a chat channel,
/// such as a new message or typing event.
///
/// Typical handling:
/// - Fetch new messages from the channel
/// - Update badge counts to reflect unread activity
/// - Refresh the chat UI to display the latest activity
@JsonSerializable(includeIfNull: false, createToJson: false)
class ChannelActivity {
  ChannelActivity({
    required this.id,
    required this.did,
    required this.type,
    this.pendingCount = 0,
    this.isEmpty = false,
    this.mediaType,
  });

  final String id;
  final String did;
  final String type; // TODO: use enum
  final int pendingCount;
  final bool isEmpty;

  /// Optional media type for `call-invite` activities (`audio` or `video`).
  ///
  /// Set by the caller when nudging the recipient so the incoming-call UI can
  /// render the correct media type immediately, without a follow-up fetch.
  final String? mediaType;

  static ChannelActivity fromJson(Map<String, dynamic> json) {
    return _$ChannelActivityFromJson(json);
  }
}
