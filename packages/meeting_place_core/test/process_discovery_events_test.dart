import 'dart:async';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
  });

  test('debounce calls to process discovery events', () async {
    void onDoneFailed() {
      fail('Debouncing failed');
    }

    final completer = Completer<void>();
    var completed = false;

    await aliceSDK.processControlPlaneEvents(
      onDone: () {
        completed = true;
        completer.complete();
      },
    );

    await aliceSDK.processControlPlaneEvents(onDone: onDoneFailed);
    await aliceSDK.processControlPlaneEvents(onDone: onDoneFailed);

    await completer.future;
    expect(completed, isTrue);
  });
}
