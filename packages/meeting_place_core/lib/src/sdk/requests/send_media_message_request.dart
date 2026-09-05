import 'dart:typed_data';

import '../../entity/channel.dart';
import '../../messaging/outgoing_message.dart' show ChannelNotification;

/// Parameters for `MeetingPlaceCoreSDK.sendMediaMessage`.
class SendMediaMessageRequest {
  const SendMediaMessageRequest({
    required this.channel,
    required this.fileBytes,
    required this.contentType,
    this.filename,
    this.caption,
    this.extraContent,
    this.notification,
  });

  /// The channel to send the media message on. The transport is selected
  /// from [Channel.transport].
  final Channel channel;

  /// The raw bytes of the media file to send.
  final Uint8List fileBytes;

  /// The MIME type of the media file.
  final String contentType;

  /// Optional filename for the media file.
  final String? filename;

  /// Optional caption to accompany the media file.
  final String? caption;

  /// Optional additional content to include alongside the media message.
  final Map<String, dynamic>? extraContent;

  /// Optional notification to send alongside the media message.
  final ChannelNotification? notification;
}
