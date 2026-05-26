import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'did_document_upload.dart';
import 'did_document_upload_exception.dart';
import 'did_document_upload_output.dart';

/// A concrete implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Upload DID
/// Document operation.
class UploadDidDocumentHandler
    implements
        CommandHandler<
          UploadDidDocumentCommand,
          UploadDidDocumentCommandOutput
        > {
  /// Returns an instance of [UploadDidDocumentHandler].
  ///
  /// **Parameters:**
  /// - [apiClient]: An instance of the Control Plane API client object.
  UploadDidDocumentHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'UploadDidDocumentHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Upload DID Document command object.
  ///
  /// **Returns:**
  /// - [UploadDidDocumentCommandOutput]: The upload DID document command
  /// output object.
  ///
  /// **Throws:**
  /// - [UploadDidDocumentException]: Exception thrown by the upload DID
  /// document operation.
  @override
  Future<UploadDidDocumentCommandOutput> handle(
    UploadDidDocumentCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Uploading DID document', name: methodName);

    try {
      final record = await _apiClient.uploadDidDocument(
        command.didDocument,
        controlProof: command.controlProof,
        proof: command.proof,
      );
      _logger.info('Uploaded DID document: ${record.did}', name: methodName);
      return UploadDidDocumentCommandOutput(record: record);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.conflict) {
        _logger.warning('DID document already registered', name: methodName);
        Error.throwWithStackTrace(
          UploadDidDocumentException.alreadyRegistered(),
          stackTrace,
        );
      }
      _logger.error(
        'Failed to upload DID document',
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        UploadDidDocumentException.generic(innerException: e),
        stackTrace,
      );
    } catch (e, stackTrace) {
      // Do not pass `error: e` to the logger: DioException carries
      // requestOptions.data which contains the JWS proof payloads.
      _logger.error(
        'Failed to upload DID document',
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        UploadDidDocumentException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
