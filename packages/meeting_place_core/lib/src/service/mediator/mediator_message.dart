import 'dart:convert';

import 'package:didcomm/didcomm.dart';

import '../../loggers/meeting_place_core_sdk_logger.dart';

class MediatorMessage {
  MediatorMessage({
    required this.plainTextMessage,
    this.messageHash,
    this.seqNo,
    this.fromDid,
  });

  final PlainTextMessage plainTextMessage;
  final String? messageHash;
  final int? seqNo;
  final String? fromDid;

  /// Create a MediatorMessage from a PlainTextMessage
  static Future<MediatorMessage> fromPlainTextMessage(
    PlainTextMessage message, {
    required MeetingPlaceCoreSDKLogger logger,
    String? messageHash,
  }) async {
    if (message.type == ProblemReportMessage.messageType) {
      logger.warning(
        'Received problem report message: ${jsonEncode(message.body)}',
        name: 'MediatorMessage.fromPlainTextMessage',
      );
    }

    return MediatorMessage(plainTextMessage: message, messageHash: messageHash);
  }

  /// Returns the message sequence number if available.
  int? get messageSequenceNumber {
    if (seqNo != null) {
      return seqNo;
    }

    final seqNoFromBody = plainTextMessage.body?['seq_no'] as int?;
    if (seqNoFromBody != null) {
      return seqNoFromBody;
    }
    return null;
  }
}
