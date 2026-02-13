import 'package:didcomm/didcomm.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';

part 'oob_connection_message.g.dart';

/// OOB connection message for direct connections (e.g., QR scanning)
/// that handles attachment exchange without notification tokens or status updates
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OobConnectionMessage {
  factory OobConnectionMessage.fromJson(Map<String, dynamic> json) =>
      _$OobConnectionMessageFromJson(json);

  factory OobConnectionMessage.fromPlainTextMessage(PlainTextMessage message) {
    return OobConnectionMessage(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: message.body ?? {},
      createdTime: message.createdTime,
      attachments: message.attachments,
    );
  }

  factory OobConnectionMessage.create({
    required String from,
    required List<String> to,
    Map<String, dynamic>? body,
    List<Attachment>? attachments,
  }) {
    return OobConnectionMessage(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: body ?? {},
      attachments: attachments,
    );
  }

  OobConnectionMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.attachments,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final Map<String, dynamic> body;
  final DateTime createdTime;
  final List<Attachment>? attachments;

  Map<String, dynamic> toJson() => _$OobConnectionMessageToJson(this);

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.oobConnectionMessage.value),
      from: from,
      to: to,
      body: body,
      createdTime: createdTime,
      attachments: attachments,
    );
  }
}
