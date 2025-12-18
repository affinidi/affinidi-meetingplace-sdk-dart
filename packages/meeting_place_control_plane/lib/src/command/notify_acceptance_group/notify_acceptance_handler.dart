import 'dart:async';

import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'notify_acceptance_group.dart';
import 'notify_acceptance_group_exception.dart';
import 'notify_acceptance_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Notify Acceptance
/// Group operation.
class NotifyAcceptanceGroupHandler
    implements
        CommandHandler<
          NotifyAcceptanceGroupCommand,
          NotifyAcceptanceGroupCommandOutput
        > {
  /// Returns an instance of [NotifyAcceptanceGroupHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  NotifyAcceptanceGroupHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'NotifyAcceptanceGroupHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Notify Acceptance Group command object.
  ///
  /// **Returns:**
  /// - [NotifyAcceptanceGroupCommandOutput]: The notify acceptance group
  /// command output object.
  ///
  /// **Throws:**
  /// - [NotifyAcceptanceGroupException]: Exception thrown by the notify
  /// acceptance group operation.
  @override
  Future<NotifyAcceptanceGroupCommandOutput> handle(
    NotifyAcceptanceGroupCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started notifying acceptance group', name: methodName);

    final builder = NotifyAcceptOfferGroupInputBuilder()
      ..mnemonic = command.mnemonic
      ..did = command.acceptOfferDid
      ..offerLink = command.offerLink
      ..senderInfo = command.senderInfo;

    try {
      _logger.info(
        '[MPX API] Calling /notify-acceptance-group with mnemonic: ${command.mnemonic}',
        name: methodName,
      );
      await _apiClient.client.notifyAcceptanceGroup(
        notifyAcceptOfferGroupInput: builder.build(),
      );

      _logger.info('Completed notifying acceptance group', name: methodName);
      return NotifyAcceptanceGroupCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Notify acceptance group for offer failed -> ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        NotifyAcceptanceGroupException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
