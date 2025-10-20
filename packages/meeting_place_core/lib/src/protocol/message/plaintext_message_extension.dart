import '../../../meeting_place_core.dart';

extension PlaintextMessageExtension on PlainTextMessage {
  bool isOfType(MeetingPlaceProtocol type) {
    return this.type.toString() == type.value;
  }
}
