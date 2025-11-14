import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';
import '../../meeting_place_protocol.dart';
import 'group_message_body.dart';

class GroupMessage {
  factory GroupMessage.fromPlainTextMessage(PlainTextMessage message) {
    return GroupMessage(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: GroupMessageBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  factory GroupMessage.create({
    required String from,
    required List<String> to,
    required GroupMessageBody body,
  }) {
    return GroupMessage(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: body,
    );
  }

  GroupMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final GroupMessageBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.groupMessage.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}
