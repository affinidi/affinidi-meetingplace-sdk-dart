import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/auth_credentials.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  final sdk = await initSDKInstance();

  test('multiple authentication calls possible', () async {
    final command = AuthenticateCommand(controlPlaneDid: getControlPlaneDid());

    await sdk.execute(command);
    final result = await sdk.execute(command);

    expect(result.credentials, isA<AuthCredentials>());
  });
}
