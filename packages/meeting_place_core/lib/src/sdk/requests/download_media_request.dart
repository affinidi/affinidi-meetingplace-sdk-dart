import '../../entity/channel.dart';
import '../../messaging/media_reference.dart';

/// Parameters for `MeetingPlaceCoreSDK.downloadMedia`.
class DownloadMediaRequest {
  const DownloadMediaRequest({required this.channel, required this.reference});

  /// The channel the media was sent on.
  final Channel channel;

  /// The transport-agnostic reference identifying the media to download.
  final MediaReference reference;
}
