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
  /// Creates a new instance of [ChannelActivity].
  ChannelActivity({
    required this.id,
    required this.did,
    required this.type,
    this.pendingCount = 0,
    this.isEmpty = false,
  });

  /// The unique identifier of this event.
  final String id;

  /// The DID of the channel this activity occurred on.
  final String did;

  /// The kind of channel activity that occurred.
  final String type; // TODO: use enum

  /// The number of pending, unread activity items on the channel.
  final int pendingCount;

  /// Whether there is no pending activity to report.
  final bool isEmpty;

  /// Creates a [ChannelActivity] from the given JSON [json].
  static ChannelActivity fromJson(Map<String, dynamic> json) {
    return _$ChannelActivityFromJson(json);
  }
}
