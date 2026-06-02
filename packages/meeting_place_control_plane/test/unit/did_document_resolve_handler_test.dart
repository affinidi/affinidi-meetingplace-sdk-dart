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
  late ResolveDidDocumentHandler handler;

  setUp(() {
    mockDidResolver = MockDidResolver();
    mockLogger = MockControlPlaneSDKLogger();
    handler = ResolveDidDocumentHandler(
      didResolver: mockDidResolver,
      logger: mockLogger,
    );
  });

  group('ResolveDidDocumentHandler', () {
    test('returns resolved DID document on success', () async {
      const did = 'did:web:example.com:user:alice';
      final document = didDocumentFixture(did);

      when(
        () => mockDidResolver.resolveDid(did),
      ).thenAnswer((_) async => document);

      final output = await handler.handle(ResolveDidDocumentCommand(did: did));

      expect(output.didDocument.id, equals(did));
    });

    test('accepts did:web hosts with encoded ports', () async {
      const did = 'did:web:example.com%3A8080:user:alice';
      final document = didDocumentFixture(did);

      when(
        () => mockDidResolver.resolveDid(did),
      ).thenAnswer((_) async => document);

      final output = await handler.handle(ResolveDidDocumentCommand(did: did));

      expect(output.didDocument.id, equals(did));
    });

    test('throws invalidDid for non-did:web input', () {
      const did = 'did:key:z6Mkf5rGMoatrSj1f4CyvuHBeXJELe9y84QFF7oNQLFMkRx';

      expect(
        () => handler.handle(ResolveDidDocumentCommand(did: did)),
        throwsA(
          isA<ResolveDidDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.resolveDidDocumentInvalidDid,
          ),
        ),
      );
      verifyNever(() => mockDidResolver.resolveDid(any()));
    });

    test('throws invalidDid for empty string', () {
      expect(
        () => handler.handle(ResolveDidDocumentCommand(did: '')),
        throwsA(
          isA<ResolveDidDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.resolveDidDocumentInvalidDid,
          ),
        ),
      );
      verifyNever(() => mockDidResolver.resolveDid(any()));
    });

    test('throws invalidDid for invalid percent-encoding in host', () {
      const did = 'did:web:example.com%GG:user:alice';

      expect(
        () => handler.handle(ResolveDidDocumentCommand(did: did)),
        throwsA(
          isA<ResolveDidDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.resolveDidDocumentInvalidDid,
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
        () => handler.handle(ResolveDidDocumentCommand(did: did)),
        throwsA(
          isA<ResolveDidDocumentException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.resolveDidDocumentGeneric,
              )
              .having((e) => e.innerException, 'innerException', resolverError),
        ),
      );
    });
  });
}
