import '../../../meeting_place_core.dart';

/// Convenience helpers on [PlainTextMessage].
extension PlaintextMessageExtension on PlainTextMessage {
  /// Whether this message's `type` matches [type].
  bool isOfType(String type) {
    return this.type.toString() == type;
  }
}
