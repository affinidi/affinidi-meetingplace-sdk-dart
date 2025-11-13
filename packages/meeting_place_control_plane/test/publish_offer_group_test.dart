import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/core/protocol/message/oob_invitation_message.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/sdk.dart';

void main() async {
  final sdk = await initSDKInstance();

  test('register offer group fails using existing mnemonic', () async {
    final device =
        Device(deviceToken: 'sample', platformType: PlatformType.didcomm);

    await sdk.execute(RegisterDeviceCommand(
        deviceToken: device.deviceToken, platformType: device.platformType));

    final mnemonic = Uuid().v4();
    final command = RegisterOfferGroupCommand(
      offerName: 'Offer name',
      offerDescription: 'Offer description',
      vCard: VCardImpl(values: {}),
      device: device,
      customPhrase: mnemonic,
      adminDid: 'did:key:1234',
      adminPublicKey: 'sample-public-key',
      adminReencryptionKey: 'sample-reencryption-key',
      oobInvitationMessage:
          OobInvitationMessage(id: Uuid().v4(), from: 'did:key:1234'),
    );

    await sdk.execute(command);

    expect(
      () => sdk.execute(command),
      throwsA(isA<ControlPlaneSDKException>().having(
          (e) => e.code, 'code', 'register_offer_group_mnemonic_in_use')),
    );
  });
}
