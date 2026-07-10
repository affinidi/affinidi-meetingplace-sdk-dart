import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

class ControlPlaneTestUtils {
  static Completer waitForControlPlaneEvent(
    MeetingPlaceCoreSDK sdk, {
    required bool Function(ControlPlaneStreamEvent event) filter,
    required int expectedNumberOfEvents,
  }) {
    final completer = Completer<void>();
    var eventCount = 0;

    sdk.controlPlaneEventsStream.listen((event) {
      if (filter(event)) {
        eventCount++;
        if (eventCount == expectedNumberOfEvents) {
          completer.complete();
        }
      }
    });

    return completer;
  }
}
