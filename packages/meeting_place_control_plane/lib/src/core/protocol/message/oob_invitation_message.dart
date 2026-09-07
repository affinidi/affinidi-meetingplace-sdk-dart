import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

/// A DIDComm out-of-band invitation message used to establish a connection
/// with a new participant.
class OobInvitationMessage extends OutOfBandMessage
    implements PlainTextMessage {
  /// Creates a new instance of [OobInvitationMessage].
  OobInvitationMessage({required super.id, required super.from})
    : super(
        body: {
          'goal_code': 'connect',
          'goal': 'Start relationship',
          'accept': ['didcomm/v2'],
        },
      );

  /// Creates an [OobInvitationMessage] from the given JSON [json].
  factory OobInvitationMessage.fromJson(Map<String, dynamic> json) {
    return OobInvitationMessage(
      id: json['id'] as String,
      from: json['from'] as String?,
    );
  }

  /// Creates an [OobInvitationMessage] with a freshly generated id from the
  /// given [from] DID.
  factory OobInvitationMessage.create({required String from}) {
    return OobInvitationMessage(id: const Uuid().v4(), from: from);
  }

  /// The DID that issued this invitation.
  @override
  String get from => super.from!;

  /// Decodes an [OobInvitationMessage] from its [toBase64] representation,
  /// merging in any [additionalProps] before parsing.
  static OobInvitationMessage fromBase64(
    String base64, [
    Map<String, dynamic> additionalProps = const {},
  ]) {
    final bytes = base64Url.decode(const Base64Codec().normalize(base64));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return OobInvitationMessage.fromJson({...json, ...additionalProps});
  }

  /// Sets the thread id of this message.
  set threadId(String? threadId) {
    this.threadId = threadId;
  }

  /// Encodes this message's JSON representation as base64url.
  String toBase64() {
    return base64UrlEncode(utf8.encode(jsonEncode(toJson())));
  }
}
