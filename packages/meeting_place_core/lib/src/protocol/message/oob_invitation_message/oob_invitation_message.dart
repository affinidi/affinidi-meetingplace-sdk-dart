import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';
import 'oob_invitation_message_body.dart';

class OobInvitationMessage extends OutOfBandMessage {
  OobInvitationMessage({required super.id, required super.from})
      : super(
          body: OobInvitationMessageBody(
            goalCode: 'connect',
            goal: 'Start relationship',
            accept: ['didcomm/v2'],
          ).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory OobInvitationMessage.fromJson(Map<String, dynamic> json) {
    return OobInvitationMessage(
      id: json['id'] as String,
      from: json['from'] as String?,
    );
  }

  factory OobInvitationMessage.create({required String from}) {
    return OobInvitationMessage(id: const Uuid().v4(), from: from);
  }

  @override
  String get from => super.from!;

  static OobInvitationMessage fromBase64(
    String base64, [
    Map<String, dynamic> additionalProps = const {},
  ]) {
    final bytes = base64Url.decode(const Base64Codec().normalize(base64));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return OobInvitationMessage.fromJson({...json, ...additionalProps});
  }

  set threadId(String? threadId) {
    this.threadId = threadId;
  }

  String toBase64() {
    return base64UrlEncode(utf8.encode(jsonEncode(toJson())));
  }
}
