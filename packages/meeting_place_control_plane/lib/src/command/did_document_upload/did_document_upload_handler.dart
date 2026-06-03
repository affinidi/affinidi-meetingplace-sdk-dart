import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/did_web_document_api.dart';
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
class UploadDidWebDocumentHandler
    implements
        CommandHandler<
          UploadDidWebDocumentCommand,
          UploadDidWebDocumentCommandOutput
        > {
  /// Returns an instance of [UploadDidWebDocumentHandler].
  ///
  /// **Parameters:**
  /// - [didWebDocumentApi]: An instance of the did:web Document API client.
  UploadDidWebDocumentHandler({
    required DidWebDocumentApi didWebDocumentApi,
    ControlPlaneSDKLogger? logger,
  }) : _didWebDocumentApi = didWebDocumentApi,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'UploadDidWebDocumentHandler';

  final DidWebDocumentApi _didWebDocumentApi;
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
  /// - [UploadDidWebDocumentCommandOutput]: The upload DID document command
  /// output object.
  ///
  /// **Throws:**
  /// - [UploadDidWebDocumentException]: Exception thrown by the upload DID
  /// document operation.
  @override
  Future<UploadDidWebDocumentCommandOutput> handle(
    UploadDidWebDocumentCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Uploading DID document', name: methodName);

    try {
      final record = await _didWebDocumentApi.uploadDidDocument(
        command.didDocument,
        controlProof: command.controlProof,
        proof: command.proof,
      );
      _logger.info('Uploaded DID document: ${record.did}', name: methodName);
      return UploadDidWebDocumentCommandOutput(record: record);
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.conflict) {
        _logger.warning('DID document already registered', name: methodName);
        Error.throwWithStackTrace(
          UploadDidWebDocumentException.alreadyRegistered(),
          stackTrace,
        );
      }
      // Do not pass `error: e` to the logger: DioException carries
      // requestOptions.data which contains the JWS proof payloads.
      _logger.error(
        'Failed to upload DID document',
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        UploadDidWebDocumentException.generic(innerException: e),
        stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to upload DID document',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        UploadDidWebDocumentException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
