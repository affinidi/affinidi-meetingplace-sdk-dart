import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'oob_invitation_message_body.dart';

class OobInvitationMessage {
  factory OobInvitationMessage.create({
    required String from,
    OobInvitationMessageBody? body,
  }) {
    return OobInvitationMessage(
      id: const Uuid().v4(),
      from: from,
      body:
          body ??
          OobInvitationMessageBody(
            goalCode: 'connect',
            goal: 'Start relationship',
            accept: ['didcomm/v2'],
          ),
    );
  }

  factory OobInvitationMessage.fromPlainTextMessage(PlainTextMessage message) {
    return OobInvitationMessage(
      id: message.id,
      from: message.from!,
      body: OobInvitationMessageBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  factory OobInvitationMessage.fromJson(Map<String, dynamic> json) {
    return OobInvitationMessage(
      id: json['id'] as String,
      from: json['from'] as String,
      body: OobInvitationMessageBody.fromJson(
        json['body'] as Map<String, dynamic>,
      ),
      createdTime: json['created_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['created_time'] * 1000,
              isUtc: true,
            )
          : null,
    );
  }

  OobInvitationMessage({
    required this.id,
    required this.from,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final OobInvitationMessageBody body;
  final DateTime createdTime;

  OutOfBandMessage toPlainTextMessage() {
    return OutOfBandMessage(
      id: id,
      from: from,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'body': body.toJson(),
      'created_time': createdTime.toIso8601String(),
    };
  }

  static OobInvitationMessage fromBase64(
    String base64, [
    Map<String, dynamic> additionalProps = const {},
  ]) {
    final bytes = base64Url.decode(const Base64Codec().normalize(base64));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return OobInvitationMessage.fromJson({...json, ...additionalProps});
  }

  String toBase64() {
    return base64UrlEncode(utf8.encode(jsonEncode(toJson())));
  }
}
