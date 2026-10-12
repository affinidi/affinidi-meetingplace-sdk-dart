import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../loggers/meeting_place_mediator_sdk_logger.dart';

/// Detects the protocol messages a mediator sends on its own behalf:
/// - Trust Task responses it stores in the inbox after processing a Trust
///   Task, e.g. an ACL update.
/// - Message pickup status replies it streams after a status request, e.g.
///   when a subscription connects.
///
/// They are mediator protocol traffic, not messages for the app, so they are
/// removed before messages reach the app.
class MediatorProtocolMessageDetector {
  static final _pickupStatusType = Uri.parse(
    'https://didcomm.org/messagepickup/3.0/status',
  );

  // Wrapping types the mediator uses for its own messages, independent of the
  // types the app expects from its peers.
  static const _mediatorWrappingTypes = [
    MessageWrappingType.authcryptPlaintext,
    MessageWrappingType.authcryptSignPlaintext,
  ];

  /// Returns the unpacked [message] if it is a protocol message sent by the
  /// mediator identified by [mediatorDid].
  ///
  /// Returns `null` for anything it cannot positively identify, so such
  /// messages take the regular path and its error handling.
  static Future<PlainTextMessage?> unpackProtocolMessage(
    Map<String, dynamic> message, {
    required DidManager recipientDidManager,
    required String mediatorDid,
    required MeetingPlaceMediatorSDKLogger logger,
  }) async {
    if (!_isSentBy(message, mediatorDid, logger)) return null;

    try {
      final plainTextMessage = await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: recipientDidManager,
        expectedMessageWrappingTypes: _mediatorWrappingTypes,
      );
      return _isProtocolMessage(plainTextMessage) ? plainTextMessage : null;
    } catch (e) {
      logger.warning(
        'Could not unpack message from the mediator, treating it as an app '
        'message: $e',
        name: 'unpackProtocolMessage',
      );
      return null;
    }
  }

  static bool _isProtocolMessage(PlainTextMessage message) =>
      TrustTaskMessage.isTrustTask(message) ||
      message.type == _pickupStatusType;

  // Checks the authcrypt sender key without decrypting, so only messages from
  // the mediator pay for the extra unpack.
  static bool _isSentBy(
    Map<String, dynamic> message,
    String mediatorDid,
    MeetingPlaceMediatorSDKLogger logger,
  ) {
    try {
      final senderKeyId = const JweHeaderConverter()
          .fromJson(EncryptedMessage.fromJson(message).protected)
          .subjectKeyId;
      return senderKeyId != null && getDidFromId(senderKeyId) == mediatorDid;
    } catch (e) {
      logger.debug(
        'Message is not an encrypted message, so not from the mediator: $e',
        name: '_isSentBy',
      );
      return false;
    }
  }
}
