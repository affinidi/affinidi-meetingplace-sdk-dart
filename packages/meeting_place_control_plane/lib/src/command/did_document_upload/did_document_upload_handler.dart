import 'dart:convert';

import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'did_document_upload.dart';
import 'did_document_upload_exception.dart';
import 'did_document_upload_output.dart';

class DidDocumentUploadHandler
    implements
        CommandHandler<DidDocumentUploadCommand, DidDocumentUploadCommandOutput> {
  DidDocumentUploadHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'DidDocumentUploadHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<DidDocumentUploadCommandOutput> handle(
    DidDocumentUploadCommand command,
  ) async {
    const methodName = 'handle';
    _logger.info(
      'Uploading did:web DID document to Control Plane',
      name: methodName,
    );

    try {
      final response = await _apiClient.dio.post<dynamic>(
        '/v1/did-document/upload',
        data: {
          'didDocument': command.didDocument,
          'controlProof': command.controlProof,
          'proof': command.proof,
        },
        options: Options(
          extra: {
            'secure': [
              {
                'type': 'apiKey',
                'name': 'DidCommTokenAuth',
                'keyName': 'authorization',
                'where': 'header',
              },
            ],
          },
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
        ),
      );

      final data = _toMap(response.data);
      if (data == null) {
        throw DidDocumentUploadException.generic(
          message:
              'Invalid upload response. status=${response.statusCode}, body=${response.data}',
        );
      }

      final did = data['did'];
      if (did is! String || did.trim().isEmpty) {
        throw DidDocumentUploadException.generic(
          message: 'Upload response missing did',
        );
      }

      return DidDocumentUploadCommandOutput(
        did: did.trim(),
        didDocUrl: (data['didDocUrl'] as String?)?.trim(),
        segment: (data['segment'] as String?)?.trim(),
      );
    } on DidDocumentUploadException {
      rethrow;
    } on DioException catch (e) {
      throw DidDocumentUploadException.generic(
        message:
            'Failed to upload DID document. status=${e.response?.statusCode}, body=${e.response?.data}',
        innerException: e,
      );
    } catch (e) {
      throw DidDocumentUploadException.generic(
        message: 'Failed to upload DID document',
        innerException: e,
      );
    }
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }
}
