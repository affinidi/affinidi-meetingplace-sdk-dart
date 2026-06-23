import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/src/command/did_document_upload/did_document_upload.dart';
import 'package:meeting_place_control_plane/src/command/did_document_upload/did_document_upload_exception.dart';
import 'package:meeting_place_control_plane/src/command/did_document_upload/did_document_upload_handler.dart';
import 'package:meeting_place_control_plane/src/control_plane_sdk_error_code.dart';
import 'package:meeting_place_control_plane/src/core/model/did_document_hosting_record.dart';
import 'package:meeting_place_control_plane/src/core/model/did_web_proof.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late MockDidWebDocumentApi mockApi;
  late MockControlPlaneSDKLogger mockLogger;
  late UploadDidWebDocumentHandler handler;

  final testProof = DidWebProof(
    type: 'JsonWebSignature2020',
    created: '2026-01-01T00:00:00Z',
    verificationMethod: 'did:web:example.com:user:alice#auth',
    proofPurpose: 'authentication',
    jws: 'test-jws',
  );

  UploadDidWebDocumentCommand makeCommand() => UploadDidWebDocumentCommand(
    didDocument: {'id': 'did:web:example.com:user:alice'},
    controlProof: testProof,
    proof: testProof,
  );

  setUp(() {
    mockApi = MockDidWebDocumentApi();
    mockLogger = MockControlPlaneSDKLogger();
    handler = UploadDidWebDocumentHandler(
      didWebDocumentApi: mockApi,
      logger: mockLogger,
    );
    registerFallbackValue(testProof);
  });

  group('UploadDidWebDocumentHandler', () {
    test('returns output on successful upload', () async {
      final record = DidDocumentHostingRecord(
        did: 'did:web:example.com:user:alice',
        segment: 'alice',
        didDocUrl: 'https://example.com/user/alice/did.json',
      );
      when(
        () => mockApi.uploadDidDocument(
          any(),
          controlProof: any(named: 'controlProof'),
          proof: any(named: 'proof'),
        ),
      ).thenAnswer((_) async => record);

      final output = await handler.handle(makeCommand());

      expect(output.record.did, equals('did:web:example.com:user:alice'));
      expect(output.record.segment, equals('alice'));
      expect(
        output.record.didDocUrl,
        equals('https://example.com/user/alice/did.json'),
      );
    });

    test('throws alreadyRegistered on HTTP 409 Conflict', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/v1/did-document/upload'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/did-document/upload'),
          statusCode: HttpStatus.conflict,
        ),
        type: DioExceptionType.badResponse,
      );
      when(
        () => mockApi.uploadDidDocument(
          any(),
          controlProof: any(named: 'controlProof'),
          proof: any(named: 'proof'),
        ),
      ).thenThrow(dioException);

      expect(
        () => handler.handle(makeCommand()),
        throwsA(
          isA<UploadDidWebDocumentException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.uploadDidWebDocumentAlreadyRegistered,
          ),
        ),
      );
    });

    test('throws generic on non-409 DioException', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/v1/did-document/upload'),
        type: DioExceptionType.connectionError,
      );
      when(
        () => mockApi.uploadDidDocument(
          any(),
          controlProof: any(named: 'controlProof'),
          proof: any(named: 'proof'),
        ),
      ).thenThrow(dioException);

      expect(
        () => handler.handle(makeCommand()),
        throwsA(
          isA<UploadDidWebDocumentException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.uploadDidWebDocumentGeneric,
              )
              .having((e) => e.innerException, 'innerException', dioException),
        ),
      );
    });

    test('throws generic on non-Dio error', () async {
      final error = Exception('unexpected error');
      when(
        () => mockApi.uploadDidDocument(
          any(),
          controlProof: any(named: 'controlProof'),
          proof: any(named: 'proof'),
        ),
      ).thenThrow(error);

      expect(
        () => handler.handle(makeCommand()),
        throwsA(
          isA<UploadDidWebDocumentException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.uploadDidWebDocumentGeneric,
              )
              .having((e) => e.innerException, 'innerException', error),
        ),
      );
    });
  });
}
