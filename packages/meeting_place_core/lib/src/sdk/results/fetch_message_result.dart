import 'package:didcomm/didcomm.dart';

class SDKFetchMessageResult {
  SDKFetchMessageResult({
    required this.plainTextMessage,
    required this.messageHash,
    this.seqNo,
    this.fromDid,
  });

  final PlainTextMessage plainTextMessage;
  final String messageHash;
  final int? seqNo;
  final String? fromDid;
}
