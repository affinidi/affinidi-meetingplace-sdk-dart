import 'dart:async';

import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'notify_acceptance.dart';
import 'notify_acceptance_exception.dart';
import 'notify_acceptance_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Notify Acceptance
/// operation.
class NotifyAcceptanceHandler
    implements
        CommandHandler<NotifyAcceptanceCommand, NotifyAcceptanceCommandOutput> {
  /// Returns an instance of [NotifyAcceptanceHandler].
  ///
  /// **Parameters:**
  /// - [discoveryApiClient] - An instance of discovery api client object.
  NotifyAcceptanceHandler({
    required ControlPlaneApiClient discoveryApiClient,
    ControlPlaneSDKLogger? logger,
  })  : _discoveryApiClient = discoveryApiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'NotifyAcceptanceHandler';

  final ControlPlaneApiClient _discoveryApiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Notify Acceptance command object.
  ///
  /// **Returns:**
  /// - [NotifyAcceptanceCommandOutput]: The notify acceptance command output
  /// object.
  ///
  /// **Throws:**
  /// - [NotifyAcceptanceException]: Exception thrown by the notify acceptance
  /// operation.
  @override
  Future<NotifyAcceptanceCommandOutput> handle(
    NotifyAcceptanceCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started handling notify acceptance', name: methodName);

    final builder = NotifyAcceptOfferInputBuilder()
      ..mnemonic = command.mnemonic
      ..did = command.acceptOfferDid
      ..offerLink = command.offerLink
      ..senderInfo = command.senderInfo;

    try {
      _logger.info(
        '[Discovery API] Calling /notify-acceptance with mnemonic: ${command.mnemonic}',
        name: methodName,
      );
      await _discoveryApiClient.client.notifyAcceptance(
        notifyAcceptOfferInput: builder.build(),
      );

      _logger.info('Completed handling notify acceptance', name: methodName);
      return NotifyAcceptanceCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to notify acceptance',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        NotifyAcceptanceException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
