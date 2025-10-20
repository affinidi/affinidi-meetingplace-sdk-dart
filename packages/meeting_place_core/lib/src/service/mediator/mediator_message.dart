import 'package:didcomm/didcomm.dart';

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
}
