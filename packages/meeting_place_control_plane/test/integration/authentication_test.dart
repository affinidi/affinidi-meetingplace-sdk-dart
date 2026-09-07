import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:test/test.dart';

import '../utils/sdk.dart';

void main() async {
  final sdk = await initSDKInstance();

  test('authenticates before executing facade methods', () async {
    final result = await sdk.registerDevice(
      RegisterDeviceRequest(
        deviceToken: 'authentication-test-device',
        platformType: PlatformType.didcomm,
      ),
    );

    expect(result.success, isTrue);
  });
}
