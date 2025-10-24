import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

class ControlPlaneTestUtils {
  static Completer waitForControlPlaneEvent(
    MeetingPlaceCoreSDK sdk, {
    required ControlPlaneEventType eventType,
    required int expectedNumberOfEvents,
  }) {
    final completer = Completer<void>();
    var eventCount = 0;

    sdk.controlPlaneEventsStream.listen((event) {
      eventCount++;
      if (event.type == eventType && eventCount == expectedNumberOfEvents) {
        completer.complete();
      }
    });

    return completer;
  }
}
