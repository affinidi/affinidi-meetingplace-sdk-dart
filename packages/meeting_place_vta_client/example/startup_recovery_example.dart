import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

import 'mocks/startup_mocks.dart';

Future<void> main() async {
  final startup = VtaStartupCapability(
    secureStore: VtaInMemorySecureStore(),
    clock: () => DateTime.utc(2026, 7, 2, 10, 0, 0),
  );

  final encodedBundle = encodeCredentialBundle(<String, dynamic>{
    'did': 'did:key:zHolder',
    'vta_url': 'https://vta.example',
    'private_key_multibase': 'z3u2secret',
    'context_id': 'ctx-personal',
    'key_id': 'holder-ed25519-1',
  });

  final snapshot = await startup.initializeFromCredentialBundle(
    encodedCredentialBundle: encodedBundle,
    config: const VtaConfig(
      baseUrl: 'https://vta.example',
      vtaDid: 'did:webvh:vta.example',
      mediatorDid: 'did:web:mediator.example',
    ),
  );

  final withAuth = await startup.persistAuthResult(
    snapshot: snapshot,
    authResult: createStartupSeedAuthResult(),
  );

  final runtime = startup.buildAuthRuntimeFromSnapshot(
    snapshot: withAuth,
    protocol: const NoopAuthProtocol(),
    transport: NoopTransport(),
  );

  print('Restored holder DID: ${runtime.snapshot.holderDid}');
  print('Hydrated access token: ${runtime.sessionManager.tokens?.accessToken}');
  print('Client auth header token: ${runtime.client.authToken}');
}
