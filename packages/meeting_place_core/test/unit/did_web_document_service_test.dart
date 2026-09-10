import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/src/service/identity/did_web_document_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockControlPlaneSDK extends Mock
    implements MeetingPlaceControlPlaneSDK {}

class _MockRootDidManager extends Mock implements DidManager {}

class _MockTargetDidManager extends Mock implements DidManager {}

class _MockWallet extends Mock implements Wallet {}

class _MockRootDidDocument extends Mock implements DidDocument {}

class _MockTargetDidDocument extends Mock implements DidDocument {}

class _MockUploadResult extends Mock implements UploadDidWebDocumentResult {}

class _FakeUploadDidWebDocumentRequest extends Fake
    implements UploadDidWebDocumentRequest {}

Map<String, dynamic> _decodeJwsPayload(String jws) {
  final payloadSegment = jws.split('.')[1];
  final decoded = base64Url.decode(base64Url.normalize(payloadSegment));
  return jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
}

void main() {
  late _MockControlPlaneSDK controlPlaneSDK;
  late _MockRootDidManager rootDidManager;
  late _MockTargetDidManager targetDidManager;
  late _MockWallet rootWallet;
  late _MockWallet targetWallet;
  late _MockRootDidDocument rootDidDocument;
  late _MockTargetDidDocument targetDidDocument;
  late DidWebDocumentService service;

  final rootAuthVm = VerificationMethodJwk(
    id: '#auth',
    controller: 'did:web:controlplane.example.com:control',
    type: 'JsonWebKey2020',
    publicKeyJwk: Jwk.fromJson({'kty': 'OKP', 'crv': 'Ed25519', 'x': 'AAAA'}),
  );
  final targetAuthVm = VerificationMethodJwk(
    id: '#auth',
    controller: 'did:web:example.com:user:alice',
    type: 'JsonWebKey2020',
    publicKeyJwk: Jwk.fromJson({'kty': 'OKP', 'crv': 'Ed25519', 'x': 'BBBB'}),
  );

  setUpAll(() {
    registerFallbackValue(_FakeUploadDidWebDocumentRequest());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    controlPlaneSDK = _MockControlPlaneSDK();
    rootDidManager = _MockRootDidManager();
    targetDidManager = _MockTargetDidManager();
    rootWallet = _MockWallet();
    targetWallet = _MockWallet();
    rootDidDocument = _MockRootDidDocument();
    targetDidDocument = _MockTargetDidDocument();

    service = DidWebDocumentService(
      controlPlaneSDK: controlPlaneSDK,
      rootDidManager: rootDidManager,
    );

    when(
      () => rootDidManager.getDidDocument(),
    ).thenAnswer((_) async => rootDidDocument);
    when(
      () => rootDidDocument.id,
    ).thenReturn('did:web:controlplane.example.com:control');
    when(() => rootDidDocument.authentication).thenReturn([rootAuthVm]);
    when(
      () => rootDidDocument.toJson(),
    ).thenReturn({'id': 'did:web:controlplane.example.com:control'});

    when(
      () => targetDidDocument.id,
    ).thenReturn('did:web:example.com:user:alice');
    when(() => targetDidDocument.authentication).thenReturn([targetAuthVm]);
    when(
      () => targetDidDocument.toJson(),
    ).thenReturn({'id': 'did:web:example.com:user:alice'});

    when(
      () => rootDidManager.getWalletKeyId(any()),
    ).thenAnswer((_) async => 'root-key-1');
    when(() => rootDidManager.wallet).thenReturn(rootWallet);
    when(() => rootWallet.getPublicKey('root-key-1')).thenAnswer(
      (_) async => PublicKey('root-key-1', Uint8List(32), KeyType.ed25519),
    );
    when(
      () => rootDidManager.sign(any(), any()),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

    when(
      () => targetDidManager.getWalletKeyId(any()),
    ).thenAnswer((_) async => 'target-key-1');
    when(() => targetDidManager.wallet).thenReturn(targetWallet);
    when(() => targetWallet.getPublicKey('target-key-1')).thenAnswer(
      (_) async => PublicKey('target-key-1', Uint8List(32), KeyType.ed25519),
    );
    when(
      () => targetDidManager.sign(any(), any()),
    ).thenAnswer((_) async => Uint8List.fromList([4, 5, 6]));

    when(
      () => controlPlaneSDK.uploadDidWebDocument(any()),
    ).thenAnswer((_) async => _MockUploadResult());
  });

  group('register', () {
    test('controlProof and proof carry byte-identical shared claims', () async {
      await service.register(
        didManager: targetDidManager,
        didDocument: targetDidDocument,
      );

      final captured = verify(
        () => controlPlaneSDK.uploadDidWebDocument(captureAny()),
      ).captured;
      final request = captured.single as UploadDidWebDocumentRequest;

      final controlPayload = _decodeJwsPayload(request.controlProof.jws);
      final docPayload = _decodeJwsPayload(request.proof.jws);

      expect(controlPayload['iat'], equals(docPayload['iat']));
      expect(controlPayload['exp'], equals(docPayload['exp']));
      expect(controlPayload['jti'], equals(docPayload['jti']));
      expect(controlPayload['operation'], equals(docPayload['operation']));
      expect(
        controlPayload['didDocumentId'],
        equals(docPayload['didDocumentId']),
      );
      expect(
        controlPayload['didDocumentHash'],
        equals(docPayload['didDocumentHash']),
      );
      expect(controlPayload['controlDid'], equals(docPayload['controlDid']));
      expect(controlPayload['aud'], equals(docPayload['aud']));
    });
  });
}
