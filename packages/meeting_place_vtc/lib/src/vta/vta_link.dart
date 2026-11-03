import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';
import 'vta_client.dart';
import 'vta_models.dart';

/// Links this phone to a member's existing VTA by hand.
///
/// The phone mints a manager key and shows its DID; the VTA's administrator
/// grants it with [grantCommands]; the phone then checks it was granted. The
/// manager key acts as the member towards their VTA: keep its seed in secure
/// storage, on this device only.
abstract final class VtaLink {
  /// Mints a new manager key to be granted on the VTA.
  static Ed25519DidKeySigner newManagerKey() => Ed25519DidKeySigner.generate();

  /// The `pnm` commands that grant [managerDid] what the phone needs: the
  /// admin role, then the `persona-holder` capability, which only the VTA's
  /// super-admin can add.
  static List<String> grantCommands(String managerDid) => [
    'pnm acl create --did $managerDid --role ${VtaAccess.adminRole} '
        '--label "Meeting Place"',
    'pnm acl update $managerDid --capabilities ${VtaAccess.personaHolder}',
  ];

  /// What the VTA lets the manager key [client] acts as do, or null while
  /// the key is not on the VTA's access list.
  ///
  /// The VTA refuses a key it does not know exactly as it refuses a bad
  /// signature, so the two are not told apart. Throws
  /// [MeetingPlaceVtcSDKException] when the VTA cannot be reached.
  static Future<VtaAccess?> access(VtaClient client) async {
    try {
      return await client.whoAmI();
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.code == MeetingPlaceVtcSDKErrorCode.refused) return null;
      rethrow;
    }
  }

  /// Whether the VTA granted the manager key [client] acts as all the phone
  /// needs: the admin role and the `persona-holder` capability.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA cannot be reached.
  static Future<bool> isGranted(VtaClient client) async =>
      (await access(client))?.isGranted ?? false;
}
