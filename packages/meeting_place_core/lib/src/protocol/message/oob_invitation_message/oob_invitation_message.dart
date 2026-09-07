import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../service/direct_connection/direct_connection_service_exception.dart';
import 'oob_invitation_message_body.dart';

/// An out-of-band DIDComm invitation, shared outside of an existing channel
/// (e.g. via a link or QR code) to start a new connection.
class OobInvitationMessage {
  /// Creates an [OobInvitationMessage] by decoding a base64url-encoded JSON
  /// payload, merging in [additionalProps].
  ///
  /// Throws a [DirectConnectionServiceException] if the payload is
  /// malformed.
  factory OobInvitationMessage.fromBase64(
    String base64, [
    Map<String, dynamic> additionalProps = const {},
  ]) {
    try {
      final bytes = base64Url.decode(const Base64Codec().normalize(base64));
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return OobInvitationMessage.fromJson({...json, ...additionalProps});
      // ignore: avoid_catching_errors
    } on TypeError catch (e) {
      throw DirectConnectionServiceException.malformedInvitation(
        innerException: e,
      );
    }
  }

  /// Creates a new [OobInvitationMessage] with a generated [id].
  factory OobInvitationMessage.create({required String from, String? type}) {
    return OobInvitationMessage(
      id: const Uuid().v4(),
      from: from,
      body: OobInvitationMessageBody(
        goalCode: type ?? 'connect',
        goal: 'Start relationship',
        accept: ['didcomm/v2'],
      ),
    );
  }

  /// Creates an [OobInvitationMessage] from a decoded [PlainTextMessage].
  factory OobInvitationMessage.fromPlainTextMessage(PlainTextMessage message) {
    return OobInvitationMessage(
      id: message.id,
      from: message.from!,
      body: OobInvitationMessageBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  /// Creates an [OobInvitationMessage] from its JSON representation.
  ///
  /// Throws a [DirectConnectionServiceException] if [json] is malformed.
  factory OobInvitationMessage.fromJson(Map<String, dynamic> json) {
    try {
      return OobInvitationMessage(
        id: json['id'] as String,
        from: json['from'] as String,
        body: OobInvitationMessageBody.fromJson(
          json['body'] as Map<String, dynamic>,
        ),
        createdTime: json['created_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['created_time'] as int) * 1000,
                isUtc: true,
              )
            : null,
      );
      // ignore: avoid_catching_errors
    } on TypeError catch (e) {
      throw DirectConnectionServiceException.malformedInvitation(
        innerException: e,
      );
    }
  }

  /// Creates an [OobInvitationMessage] from its constituent message fields.
  OobInvitationMessage({
    required this.id,
    required this.from,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  /// The DIDComm message id.
  final String id;

  /// The DID of the inviting party.
  final String from;

  /// The message body carrying the invitation's goal and accepted formats.
  final OobInvitationMessageBody body;

  /// When this message was created.
  final DateTime createdTime;

  /// Converts this message to an [OutOfBandMessage] for transport.
  OutOfBandMessage toPlainTextMessage() {
    return OutOfBandMessage(
      id: id,
      from: from,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }

  /// Converts this message to its JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'body': body.toJson(),
      'created_time': createdTime.toIso8601String(),
    };
  }

  /// Encodes this message as base64url-encoded JSON.
  String toBase64() {
    return base64UrlEncode(utf8.encode(jsonEncode(toJson())));
  }
}
