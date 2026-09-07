import 'package:json_annotation/json_annotation.dart';

part 'channel_inauguration_body.g.dart';

/// The body of a channel-inauguration message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChannelInaugurationBody {
  /// Creates a [ChannelInaugurationBody] from its JSON representation.
  factory ChannelInaugurationBody.fromJson(Map<String, dynamic> json) =>
      _$ChannelInaugurationBodyFromJson(json);

  /// Creates a [ChannelInaugurationBody].
  ChannelInaugurationBody({required this.notificationToken, required this.did});

  /// The token used to send push notifications to the channel initiator.
  @JsonKey(name: 'notification_token')
  final String notificationToken;

  /// The DID of the new channel.
  @JsonKey(name: 'did')
  final String did;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$ChannelInaugurationBodyToJson(this);
}
