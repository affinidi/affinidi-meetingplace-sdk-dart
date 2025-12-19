import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'channel_inauguration_body.dart';

class ChannelInauguration {
  factory ChannelInauguration.fromPlainTextMessage(PlainTextMessage message) {
    return ChannelInauguration(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChannelInaugurationBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  factory ChannelInauguration.create({
    required String from,
    required List<String> to,
    required String notificationToken,
    required String did,
  }) {
    return ChannelInauguration(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: ChannelInaugurationBody(
        notificationToken: notificationToken,
        did: did,
      ),
    );
  }

  ChannelInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChannelInaugurationBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.channelInauguration.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
