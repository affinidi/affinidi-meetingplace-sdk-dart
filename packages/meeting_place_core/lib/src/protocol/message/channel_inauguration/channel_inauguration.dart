import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'channel_inauguration_body.dart';

/// A channel-inauguration DIDComm message, sent to establish a new channel
/// between two parties.
class ChannelInauguration {
  /// Creates a [ChannelInauguration] from a decoded [PlainTextMessage].
  factory ChannelInauguration.fromPlainTextMessage(PlainTextMessage message) {
    return ChannelInauguration(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChannelInaugurationBody.fromJson(message.body!),
      createdTime: message.createdTime,
      attachments: message.attachments,
    );
  }

  /// Creates a new [ChannelInauguration] message with a generated [id].
  factory ChannelInauguration.create({
    required String from,
    required List<String> to,
    required String notificationToken,
    required String did,
    List<Attachment>? attachments,
  }) {
    return ChannelInauguration(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChannelInaugurationBody(
        notificationToken: notificationToken,
        did: did,
      ),
      attachments: attachments,
    );
  }

  /// Creates a [ChannelInauguration] from its constituent message fields.
  ChannelInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.attachments,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  /// The DIDComm message id.
  final String id;

  /// The DID of the sender.
  final String from;

  /// The DIDs of the message recipients.
  final List<String> to;

  /// The message body carrying the new channel's DID and notification
  /// token.
  final ChannelInaugurationBody body;

  /// When this message was created.
  final DateTime createdTime;

  /// Attachments carried alongside this message.
  final List<Attachment>? attachments;

  /// Converts this message to a [PlainTextMessage] for transport.
  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.channelInauguration.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
      attachments: attachments,
    );
  }
}
