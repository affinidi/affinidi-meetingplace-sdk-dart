import 'package:dio/dio.dart';

import '../core/model/did_document_hosting_record.dart';
import '../core/model/did_web_proof.dart';

/// API client for did:web DID Document operations on the Control Plane.
class DidWebDocumentApi {
  DidWebDocumentApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _secure = <Map<String, String>>[
    {
      'type': 'apiKey',
      'name': 'DidCommTokenAuth',
      'keyName': 'authorization',
      'where': 'header',
    },
  ];

  /// Uploads (creates) a new did:web DID Document on the Control Plane.
  Future<DidDocumentHostingRecord> uploadDidDocument(
    Map<String, dynamic> didDocument, {
    required DidWebProof controlProof,
    required DidWebProof proof,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/did-document/upload',
      data: {
        'didDocument': didDocument,
        'controlProof': controlProof.toJson(),
        'proof': proof.toJson(),
      },
      options: Options(extra: {'secure': _secure}),
    );
    final data = response.data;
    if (data == null) {
      throw StateError(
        'uploadDidDocument: server returned a successful status but no body.',
      );
    }
    return DidDocumentHostingRecord.fromJson(data);
  }
}
