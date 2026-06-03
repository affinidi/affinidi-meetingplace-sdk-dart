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
class ResolveDidWebDocumentHandler
    implements
        CommandHandler<
          ResolveDidWebDocumentCommand,
          ResolveDidWebDocumentCommandOutput
        > {
  /// Returns an instance of [ResolveDidWebDocumentHandler].
  ///
  /// **Parameters:**
  /// - [didResolver]: An instance of the DID resolver object.
  ResolveDidWebDocumentHandler({
    required DidResolver didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _didResolver = didResolver,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'ResolveDidWebDocumentHandler';

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
  /// - [ResolveDidWebDocumentCommandOutput]: The resolve DID document command
  /// output object.
  ///
  /// **Throws:**
  /// - [ResolveDidWebDocumentException]: Exception thrown by the resolve DID
  /// document operation.
  @override
  Future<ResolveDidWebDocumentCommandOutput> handle(
    ResolveDidWebDocumentCommand command,
  ) async {
    final methodName = 'handle';

    if (!command.did.startsWith('did:web:')) {
      throw ResolveDidWebDocumentException.invalidDid(did: command.did);
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
      return ResolveDidWebDocumentCommandOutput(didDocument: didDocument);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to resolve DID document for: ${command.did}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        ResolveDidWebDocumentException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
