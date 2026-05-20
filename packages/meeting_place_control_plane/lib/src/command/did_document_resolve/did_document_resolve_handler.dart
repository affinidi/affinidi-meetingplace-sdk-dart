import 'package:ssi/ssi.dart';

import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'did_document_resolve.dart';
import 'did_document_resolve_output.dart';

/// Handles the Resolve DID Document operation.
///
/// Uses the SSI [DidResolver] to resolve a did:web DID Document.
/// [UniversalDIDResolver] handles did:web natively via HTTP — no custom
/// endpoint is needed.
class ResolveDidDocumentHandler
    implements
        CommandHandler<
          ResolveDidDocumentCommand,
          ResolveDidDocumentCommandOutput
        > {
  ResolveDidDocumentHandler({
    required this.didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'ResolveDidDocumentHandler';

  final DidResolver didResolver;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<ResolveDidDocumentCommandOutput> handle(
    ResolveDidDocumentCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Resolving DID document for: ${command.did}',
      name: methodName,
    );

    try {
      final didDocument = await didResolver.resolveDid(command.did);
      _logger.info(
        'Resolved DID document for: ${command.did}',
        name: methodName,
      );
      return ResolveDidDocumentCommandOutput(didDocument: didDocument);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to resolve DID document for: ${command.did}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
