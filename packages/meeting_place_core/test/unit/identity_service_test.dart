import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/identity/did_web_document_service.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockMatrixService extends Mock implements MatrixService {}

class _MockWallet extends Mock implements Wallet {}

class _MockDidManager extends Mock implements DidManager {}

class _MockDidDocument extends Mock implements DidDocument {}

class _FakeDidManager extends Fake implements DidManager {}

class _FakeDidDocument extends Fake implements DidDocument {}

class _MockDidWebDocumentService extends Mock
    implements DidWebDocumentService {}

void main() {
  late _MockConnectionManager mockConnectionManager;
  late _MockMatrixService mockMatrixService;
  late _MockWallet mockWallet;
  late _MockDidManager mockDidManager;
  late _MockDidDocument mockDidDocument;
  late _MockDidWebDocumentService mockDidDocumentService;
  late IdentityService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(_FakeDidManager());
    registerFallbackValue(_FakeDidDocument());
  });

  setUp(() {
    mockConnectionManager = _MockConnectionManager();
    mockMatrixService = _MockMatrixService();
    mockWallet = _MockWallet();
    mockDidManager = _MockDidManager();
    mockDidDocument = _MockDidDocument();
    mockDidDocumentService = _MockDidWebDocumentService();

    service = IdentityService(
      connectionManager: mockConnectionManager,
      matrixService: mockMatrixService,
      didWebDocumentService: mockDidDocumentService,
      didWebBaseHost: Uri.parse('https://example.com'),
    );

    when(() => mockDidDocument.id).thenReturn('did:test:permanent');
    when(
      () => mockConnectionManager.generateDidWeb(
        mockWallet,
        baseHost: any(named: 'baseHost'),
      ),
    ).thenAnswer((_) async => mockDidManager);
    when(
      () => mockDidManager.getDidDocument(),
    ).thenAnswer((_) async => mockDidDocument);
    when(
      () => mockDidDocumentService.register(
        didManager: any(named: 'didManager'),
        didDocument: any(named: 'didDocument'),
      ),
    ).thenAnswer((_) async {});
  });

  group('createPermanentIdentity', () {
    test('calls loginWithDid when transport is matrix', () async {
      when(
        () => mockMatrixService.loginWithDid(any()),
      ).thenAnswer((_) async => '@user:matrix.test');

      final result = await service.createPermanentIdentity(
        mockWallet,
        transport: ChannelTransport.matrix,
      );

      verify(() => mockMatrixService.loginWithDid(mockDidManager)).called(1);
      expect(result.matrixUserId, equals('@user:matrix.test'));
      expect(result.didManager, equals(mockDidManager));
      expect(result.didDocument, equals(mockDidDocument));
    });

    test('does not call loginWithDid when transport is didcomm', () async {
      final result = await service.createPermanentIdentity(
        mockWallet,
        transport: ChannelTransport.didcomm,
      );

      verifyNever(() => mockMatrixService.loginWithDid(any()));
      expect(result.matrixUserId, isNull);
      expect(result.didManager, equals(mockDidManager));
      expect(result.didDocument, equals(mockDidDocument));
    });
  });
}
