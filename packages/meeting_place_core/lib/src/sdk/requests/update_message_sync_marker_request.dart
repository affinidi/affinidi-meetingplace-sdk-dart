import '../../entity/channel.dart';

/// Parameters for `MeetingPlaceCoreSDK.updateMessageSyncMarker`.
class UpdateMessageSyncMarkerRequest {
  const UpdateMessageSyncMarkerRequest({
    required this.channel,
    required this.eventId,
  });

  /// The channel whose sync marker is being updated.
  final Channel channel;

  /// The transport event ID to anchor the channel's sync marker on.
  final String eventId;
}
