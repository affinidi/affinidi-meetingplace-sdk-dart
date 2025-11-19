import 'package:didcomm/didcomm.dart';

class MediatorStreamData {
  MediatorStreamData({
    required this.message,
    required this.messageHash,
  });

  final PlainTextMessage message;
  final String messageHash;
}
