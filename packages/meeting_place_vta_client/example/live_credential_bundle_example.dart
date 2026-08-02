import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

import 'support/generated_proof_signer.dart';

// Replace these values before running
// VTA_CREDENTIAL_BUNDLE: base64url-encoded bundle from pnm bootstrap open
// VTA_DID: from `cargo run --package pnm-cli -- vta info` (VTA DID field)
// HOLDER_SEED_HEX: optional, defaults to the demo seed below
const _encodedBundle = 'YOUR_CREDENTIAL_BUNDLE_HERE';
const _vtaDid = 'YOUR_VTA_DID_HERE';
// Demo seed — always derives the same DID, fine for local testing.
// For a real identity: run `openssl rand -hex 32` to generate a new seed,
// then import the derived DID once:
//   dart run example/live_vta_auth_example.dart  (prints: Using holder DID: ...)
//   cargo run --package vta-service -- import-did --did <printed-did> --role admin
const _holderSeedHex =
    '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

Future<void> main() async {
  if (_encodedBundle == 'YOUR_CREDENTIAL_BUNDLE_HERE' ||
      _vtaDid == 'YOUR_VTA_DID_HERE') {
    throw Exception(
      'Replace _encodedBundle and _vtaDid at the top of this file before running.',
    );
  }

  final signer = await GeneratedProofSigner.fromSeedHex(_holderSeedHex);
  final holderDid = signer.didKey;

  final bundle = VtaCredentialBundle.parse(_encodedBundle.trim());
  print('holderDid: ${bundle.did}');
  print('vtaUrl: ${bundle.vtaUrl}');
  print('contextId: ${bundle.contextId}');
  print('keyId: ${bundle.keyId}');

  if (bundle.did != holderDid) {
    throw Exception(
      'Bundle DID (${bundle.did}) does not match signer DID ($holderDid). '
      'Use the matching HOLDER_SEED_HEX.',
    );
  }

  final client = VtaClient(baseUrl: bundle.vtaUrl);
  final protocol = TrustTaskVtaAuthProtocol(signer: signer);
  final workflow = VtaAuthWorkflow(
    client: client,
    holderDid: holderDid,
    vtaDid: _vtaDid,
    protocol: protocol,
  );

  try {
    final auth = await workflow.connect();
    print('Connected. session=${auth.session.sessionId}');

    final whoami = await workflow.whoAmI();
    print('whoami subject=${whoami.subject} roles=${whoami.roles}');
  } on VtaException catch (error) {
    final isAclForbidden =
        error.statusCode == 403 ||
        error.type == VtaErrorType.acl ||
        error.code == 'e.vta.auth.forbidden';
    if (isAclForbidden) {
      print('DID is not in ACL. Add it, then run the example again.');
      print('From VTI repo:');
      print(
        '  cargo run --package pnm-cli -- acl create --did $holderDid --role admin',
      );
      print(
        '  If locked out: cargo run --package vta-service -- import-did --did $holderDid --role admin',
      );
      return;
    }
    rethrow;
  }
}
