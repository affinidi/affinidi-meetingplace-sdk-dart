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
    onDoneFailed(List<Object> errors) {
      fail('Debouncing failed');
    }

    final completer = Completer<void>();
    bool completed = false;

    unawaited(
      aliceSDK.processControlPlaneEvents(
        onDone: (List<Object> errors) {
          completed = true;
          completer.complete();
        },
      ),
    );

    unawaited(aliceSDK.processControlPlaneEvents(onDone: onDoneFailed));
    unawaited(aliceSDK.processControlPlaneEvents(onDone: onDoneFailed));

    await completer.future;
    expect(completed, isTrue);
  });
}
