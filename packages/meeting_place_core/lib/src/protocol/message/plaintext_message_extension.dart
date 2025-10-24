import '../../../meeting_place_core.dart';

extension PlaintextMessageExtension on PlainTextMessage {
  bool isOfType(String type) {
    return this.type.toString() == type;
  }
}
