import 'package:didcomm/didcomm.dart' show Attachment;

import 'entity/channel.dart';

/// Emitted when the remote party delivers DIDComm attachments during
/// channel inauguration.
class ChannelAttachmentEvent {
  ChannelAttachmentEvent({required this.channel, required this.attachments});

  /// The channel through which the attachments arrived.
  final Channel channel;

  /// The attachments delivered by the remote party.
  final List<Attachment> attachments;
}
