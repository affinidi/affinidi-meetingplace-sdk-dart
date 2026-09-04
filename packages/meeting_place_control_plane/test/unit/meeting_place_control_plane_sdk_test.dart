import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockDidManager extends Mock implements DidManager {}

class _MockDidResolver extends Mock implements DidResolver {}

void main() {
  late MeetingPlaceControlPlaneSDK sdk;

  setUp(() {
    sdk = MeetingPlaceControlPlaneSDK(
      didManager: _MockDidManager(),
      controlPlaneDid: 'did:web:123456789abcdefghi',
      mediatorDid: 'did:web:mediator',
      didResolver: _MockDidResolver(),
    );
  });

  group('MeetingPlaceControlPlaneSDK.device', () {
    test(
      'throws MeetingPlaceControlPlaneSDKException with missingDevice code '
      'when no device has been set',
      () {
        expect(
          () => sdk.device,
          throwsA(
            isA<MeetingPlaceControlPlaneSDKException>().having(
              (e) => e.code,
              'code',
              MeetingPlaceControlPlaneSDKErrorCode.missingDevice.value,
            ),
          ),
        );
      },
    );

    test('returns the device once one has been set', () {
      final device = Device(
        deviceToken: 'token',
        platformType: PlatformType.pushNotification,
      );

      sdk.device = device;

      expect(sdk.device, same(device));
    });
  });
}
