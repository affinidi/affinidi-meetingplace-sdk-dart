import 'dart:async';

import 'package:ssi/ssi.dart';

import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'did_document_resolve.dart';
import 'did_document_resolve_exception.dart';
import 'did_document_resolve_output.dart';

/// A concrete implementation of the [CommandHandler] interface.
///
/// Handles DID resolution by delegating to the injected [DidResolver].
/// This also handles the exception that are returned by the resolver.
class ResolveDidDocumentHandler
    implements
        CommandHandler<
          ResolveDidDocumentCommand,
          ResolveDidDocumentCommandOutput
        > {
  /// Returns an instance of [ResolveDidDocumentHandler].
  ///
  /// **Parameters:**
  /// - [didResolver]: An instance of the DID resolver object.
  ResolveDidDocumentHandler({
    required DidResolver didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _didResolver = didResolver,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'ResolveDidDocumentHandler';

  final DidResolver _didResolver;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This resolves the given did:web DID using the injected [DidResolver] and
  /// validates the returned data for Resolve DID Document operation.
  ///
  /// **Parameters:**
  /// - [command]: Resolve DID Document command object.
  ///
  /// **Returns:**
  /// - [ResolveDidDocumentCommandOutput]: The resolve DID document command
  /// output object.
  ///
  /// **Throws:**
  /// - [ResolveDidDocumentException]: Exception thrown by the resolve DID
  /// document operation.
  @override
  Future<ResolveDidDocumentCommandOutput> handle(
    ResolveDidDocumentCommand command,
  ) async {
    final methodName = 'handle';

    if (!_isValidDidWeb(command.did)) {
      throw ResolveDidDocumentException.invalidDid(did: command.did);
    }

    _logger.info(
      'Resolving DID document for: ${command.did}',
      name: methodName,
    );

    try {
      final didDocument = await _didResolver.resolveDid(command.did);
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
      Error.throwWithStackTrace(
        ResolveDidDocumentException.generic(innerException: e),
        stackTrace,
      );
    }
  }

  /// Returns true if [did] is a syntactically valid did:web identifier.
  ///
  /// Rejects percent-encoded characters to block port-injection attacks
  /// (e.g. `did:web:host%3A8080:path`).
  static bool _isValidDidWeb(String did) {
    return did.startsWith('did:web:') && did.length > 8 && !did.contains('%');
  }
}
