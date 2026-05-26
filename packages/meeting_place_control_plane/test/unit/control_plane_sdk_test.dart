import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _FakeDidResolver implements DidResolver {
  _FakeDidResolver(this._documents);

  final Map<String, DidDocument> _documents;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final document = _documents[did];
    if (document == null) {
      throw Exception('Missing DID document for $did');
    }
    return document;
  }
}

DidDocument _didDocument(String did) => DidDocument.fromJson({
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': did,
  'verificationMethod': const <Object>[],
  'authentication': const <Object>[],
});

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
  test('ResolveDidDocumentCommand does not force SDK authentication', () async {
    const controlPlaneDid = 'did:web:control.example.com';
    const hostedDid = 'did:web:example.com:user:alice';

    final resolver = _FakeDidResolver({hostedDid: _didDocument(hostedDid)});

    final sdk = await _buildSdk(
      controlPlaneDid: controlPlaneDid,
      didResolver: resolver,
    );

    final output = await sdk.execute(ResolveDidDocumentCommand(did: hostedDid));

    expect(output.didDocument.id, hostedDid);
    expect(sdk.isInitialized, isFalse);
  });

  test(
    'ResolveDidDocumentCommand accepts did:web hosts with encoded ports',
    () async {
      const controlPlaneDid = 'did:web:control.example.com';
      const hostedDid = 'did:web:example.com%3A3000:user:alice';

      final resolver = _FakeDidResolver({hostedDid: _didDocument(hostedDid)});

      final sdk = await _buildSdk(
        controlPlaneDid: controlPlaneDid,
        didResolver: resolver,
      );

      final output = await sdk.execute(
        ResolveDidDocumentCommand(did: hostedDid),
      );

      expect(output.didDocument.id, hostedDid);
      expect(sdk.isInitialized, isFalse);
    },
  );
}
