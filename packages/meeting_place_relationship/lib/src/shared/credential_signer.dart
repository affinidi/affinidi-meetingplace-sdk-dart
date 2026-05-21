import 'package:ssi/ssi.dart';

import '../meeting_place_relationship_sdk_exception.dart';

/// Signs Verifiable Credentials using the first assertion method key
/// of a [DidManager].
abstract final class CredentialSigner {
  /// Signs [unsigned] using the first assertion method key from [manager].
  ///
  /// Throws [MeetingPlaceRelationshipSDKException] if [manager] has no
  /// assertion method keys.
  static Future<VcDataModelV2> sign(
    VcDataModelV2 unsigned,
    DidManager manager,
  ) async {
    final assertionMethod = manager.assertionMethod.firstOrNull;
    if (assertionMethod == null) {
      throw MeetingPlaceRelationshipSDKException.signingKeyUnavailable();
    }
    final suite = LdVcDm2Suite();
    final signer = await manager.getSigner(assertionMethod);
    return await suite.issue(
          unsignedData: unsigned,
          proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: signer),
        )
        as VcDataModelV2;
  }
}
