import 'package:ssi/ssi.dart';

/// Signs Verifiable Credentials using the first assertion method key
/// of a [DidManager].
abstract final class CredentialSigner {
  /// Signs [unsigned] using the first assertion method key from [manager].
  ///
  /// Throws [StateError] if [manager] has no assertion method keys.
  static Future<VerifiableCredential> sign(
    VcDataModelV2 unsigned,
    DidManager manager,
  ) async {
    final assertionMethod = manager.assertionMethod.firstOrNull;
    if (assertionMethod == null) {
      throw StateError(
        'DidManager has no assertionMethod keys available for signing',
      );
    }
    final suite = LdVcDm2Suite();
    final signer = await manager.getSigner(assertionMethod);
    return suite.issue(
      unsignedData: unsigned,
      proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: signer),
    );
  }
}
