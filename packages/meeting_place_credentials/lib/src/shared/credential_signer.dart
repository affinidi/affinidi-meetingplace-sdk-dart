import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_credentials_sdk_exception.dart';

/// Signs Verifiable Credentials using the first assertion method key
/// of a [DidManager].
abstract final class CredentialSigner {
  /// Signs [unsigned] using the first assertion method key from [manager].
  ///
  /// A key held outside this device, through [ExternalConnectionKeys], signs
  /// with `eddsa-jcs-2022` where it is held; a device key signs with
  /// `ecdsa-jcs-2019`.
  ///
  /// Throws [MeetingPlaceCredentialsSDKException] if [manager] has no
  /// assertion method keys, or the external key's holder signs other than as
  /// the credential's issuer. Errors of the holder itself, such as it being
  /// unreachable, are thrown as the holder throws them.
  static Future<VcDataModelV2> sign(
    VcDataModelV2 unsigned,
    DidManager manager,
  ) async {
    final assertionMethod = manager.assertionMethod.firstOrNull;
    if (assertionMethod == null) {
      throw MeetingPlaceCredentialsSDKException.signingKeyUnavailable();
    }
    final suite = LdVcDm2Suite();
    final wallet = manager.wallet;
    final walletKeyId = await manager.getWalletKeyId(assertionMethod);
    if (wallet is ExternalKeyWallet &&
        walletKeyId != null &&
        wallet.isExternal(walletKeyId)) {
      return _signExternally(unsigned, wallet, walletKeyId, suite);
    }

    final signer = await manager.getSigner(assertionMethod);
    return await suite.issue(
          unsignedData: unsigned,
          proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: signer),
        )
        as VcDataModelV2;
  }

  static Future<VcDataModelV2> _signExternally(
    VcDataModelV2 unsigned,
    ExternalKeyWallet wallet,
    String walletKeyId,
    LdVcDm2Suite suite,
  ) async {
    final document = unsigned.toJson()..remove('proof');
    final signed = await wallet.signDocument(
      document,
      walletKeyId: walletKeyId,
    );
    final proof = signed['proof'];
    final issuer = Issuer.fromJson(document['issuer']).id.toString();
    if (proof is! Map<String, dynamic> ||
        proof['cryptosuite'] != 'eddsa-jcs-2022' ||
        (proof['verificationMethod'] as String?)?.split('#').first != issuer) {
      throw MeetingPlaceCredentialsSDKException.externalSignatureInvalid();
    }
    return suite.parse(jsonEncode({...document, 'proof': proof}));
  }
}
