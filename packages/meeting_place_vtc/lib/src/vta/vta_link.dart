import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';
import 'vta_client.dart';

/// Links this phone to a member's existing VTA by hand.
///
/// The phone mints a manager key and shows its DID; the VTA's administrator
/// grants it, e.g. `pnm --vta <name> acl create --did <did> --role admin`;
/// the phone then checks it was added. The manager key acts as the member
/// towards their VTA: keep its seed in secure storage, on this device only.
abstract final class VtaLink {
  /// Mints a new manager key to be granted on the VTA.
  static Ed25519DidKeySigner newManagerKey() => Ed25519DidKeySigner.generate();

  /// Whether the VTA has granted the manager key [client] acts as.
  ///
  /// Returns false while the key is not on the VTA's access list yet. Throws
  /// [MeetingPlaceVtcSDKException] when the VTA cannot be reached.
  static Future<bool> isGranted(VtaClient client) async {
    try {
      await client.whoAmI();
      return true;
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.code == MeetingPlaceVtcSDKErrorCode.refused) return false;
      rethrow;
    }
  }
}
