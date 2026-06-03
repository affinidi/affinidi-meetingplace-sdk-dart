import 'package:meeting_place_control_plane/src/command/did_document_resolve/did_document_resolve.dart';
import 'package:meeting_place_control_plane/src/command/did_document_resolve/did_document_resolve_exception.dart';
import 'package:meeting_place_control_plane/src/command/did_document_resolve/did_document_resolve_handler.dart';
import 'package:meeting_place_control_plane/src/control_plane_sdk_error_code.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late MockDidResolver mockDidResolver;
  late MockControlPlaneSDKLogger mockLogger;
  late ResolveDidWebDocumentHandler handler;

  setUp(() {
    mockDidResolver = MockDidResolver();
    mockLogger = MockControlPlaneSDKLogger();
    handler = ResolveDidWebDocumentHandler(
      didResolver: mockDidResolver,
      logger: mockLogger,
    );
  });

  group('ResolveDidWebDocumentHandler', () {
    test('returns resolved DID document on success', () async {
      const did = 'did:web:example.com:user:alice';
      final document = didDocumentFixture(did);

      when(
        () => mockDidResolver.resolveDid(did),
      ).thenAnswer((_) async => document);

      final output = await handler.handle(
        ResolveDidWebDocumentCommand(did: did),
      );

      expect(output.didDocument.id, equals(did));
    });

    test('throws invalidDid for non-did:web input', () {
      const did = 'did:key:z6Mkf5rGMoatrSj1f4CyvuHBeXJELe9y84QFF7oNQLFMkRx';

      expect(
        () => handler.handle(ResolveDidWebDocumentCommand(did: did)),
        throwsA(
          isA<ResolveDidWebDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.resolveDidWebDocumentInvalidDid,
          ),
        ),
      );
      verifyNever(() => mockDidResolver.resolveDid(any()));
    });

    test('throws invalidDid for empty string', () {
      expect(
        () => handler.handle(ResolveDidWebDocumentCommand(did: '')),
        throwsA(
          isA<ResolveDidWebDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.resolveDidWebDocumentInvalidDid,
          ),
        ),
      );
      verifyNever(() => mockDidResolver.resolveDid(any()));
    });

    test('throws generic when resolver throws', () async {
      const did = 'did:web:example.com:user:alice';
      final resolverError = Exception('network error');

      when(() => mockDidResolver.resolveDid(did)).thenThrow(resolverError);

      expect(
        () => handler.handle(ResolveDidWebDocumentCommand(did: did)),
        throwsA(
          isA<ResolveDidWebDocumentException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.resolveDidWebDocumentGeneric,
              )
              .having((e) => e.innerException, 'innerException', resolverError),
        ),
      );
    });
  });
}
