import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'did_document_upload.dart';
import 'did_document_upload_output.dart';

/// Handles the Upload DID Document operation.
///
/// Sends a POST request to `/v1/did-document/upload` on the Control Plane API
/// to create and store a new did:web DID Document.
class UploadDidDocumentHandler
    implements
        CommandHandler<
          UploadDidDocumentCommand,
          UploadDidDocumentCommandOutput
        > {
  UploadDidDocumentHandler({
    required this.apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'UploadDidDocumentHandler';

  final ControlPlaneApiClient apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<UploadDidDocumentCommandOutput> handle(
    UploadDidDocumentCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Uploading DID document', name: methodName);

    try {
      final record = await apiClient.uploadDidDocument(
        command.didDocument,
        controlProof: command.controlProof,
        proof: command.proof,
      );
      _logger.info('Uploaded DID document: ${record.did}', name: methodName);
      return UploadDidDocumentCommandOutput(record: record);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to upload DID document',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
