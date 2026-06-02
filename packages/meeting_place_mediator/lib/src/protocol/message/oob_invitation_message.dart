import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

/// [OobInvitationMessage] is a special type of [OutOfBandMessage].
/// Represents an out-of-band invitation message.
///
/// **Parameters:**
/// - [id]: Unique identifier for the message ("id" field in DIDComm spec).
/// - [from]: Sender's DID.
class OobInvitationMessage extends OutOfBandMessage {
  OobInvitationMessage({required super.id, required super.from})
      : super(
          body: {
            'goal_code': 'connect',
            'goal': 'Start relationship',
            'accept': ['didcomm/v2'],
          },
        );

  /// Factory constructor to create a [OobInvitationMessage] from JSON.
  ///
  /// **Parameters:**
  /// - [json]: The JSON map containing serialized [OobInvitationMessage] data.
  factory OobInvitationMessage.fromJson(Map<String, dynamic> json) {
    return OobInvitationMessage(
      id: json['id'] as String,
      from: json['from'] as String?,
    );
  }

  /// Factory constructor to create a [OobInvitationMessage] from sender's DID.
  ///
  /// **Parameters**
  /// - [from]: Sender's DID.
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
