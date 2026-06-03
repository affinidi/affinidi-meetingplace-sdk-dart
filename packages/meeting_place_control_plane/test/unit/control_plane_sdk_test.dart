import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'mocks.dart';

Future<ControlPlaneSDK> _buildSdk({
  required String controlPlaneDid,
  required DidResolver didResolver,
}) async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod((await wallet.generateKey()).id);
  return ControlPlaneSDK(
    didManager: didManager,
    controlPlaneDid: controlPlaneDid,
    mediatorDid: 'did:web:example.com:mediator',
    didResolver: didResolver,
  );
}

void main() {
  test(
    'ResolveDidWebDocumentCommand does not force SDK authentication',
    () async {
      const controlPlaneDid = 'did:web:control.example.com';
      const hostedDid = 'did:web:example.com:user:alice';

      final resolver = FakeDidResolver({
        hostedDid: didDocumentFixture(hostedDid),
      });

      final sdk = await _buildSdk(
        controlPlaneDid: controlPlaneDid,
        didResolver: resolver,
      );

      final output = await sdk.execute(
        ResolveDidWebDocumentCommand(did: hostedDid),
      );

      expect(output.didDocument.id, hostedDid);
      expect(sdk.isInitialized, isFalse);
    },
  );
}
