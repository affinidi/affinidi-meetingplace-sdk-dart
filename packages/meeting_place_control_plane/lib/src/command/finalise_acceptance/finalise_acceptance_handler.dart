import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../command.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Finalise
/// Acceptance operation.
class FinaliseAcceptanceHandler
    implements
        CommandHandler<FinaliseAcceptanceCommand, FinaliseAcceptanceOutput> {
  /// Returns an instance of [FinaliseAcceptanceHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  FinaliseAcceptanceHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'FinaliseAcceptanceHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Finalise Acceptance command object.
  ///
  /// **Returns:**
  /// - [FinaliseAcceptanceOutput]: The finalise acceptance command
  /// output object.
  ///
  /// **Throws:**
  /// - [FinaliseAcceptanceException]: Exception thrown by the finalise
  /// acceptance operation.
  @override
  Future<FinaliseAcceptanceOutput> handle(
    FinaliseAcceptanceCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started finalising acceptance ', name: methodName);

    final builder = FinaliseOfferInputBuilder()
      ..mnemonic = command.mnemonic
      ..did = command.otherPartyAcceptOfferDid
      ..offerLink = command.offerLink
      ..theirDid = command.otherPartyPermanentChannelDid
      ..deviceToken = command.device.deviceToken
      ..platformType = FinaliseOfferInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      );

    try {
      _logger.info(
        '[MPX API] Calling /finalise-acceptance for mnemonic: ${command.mnemonic}',
        name: methodName,
      );

      final response = await _apiClient.client.finaliseOfferAcceptance(
        finaliseOfferInput: builder.build(),
      );

      _logger.info('Completed finalising acceptance', name: methodName);
      return FinaliseAcceptanceOutput(
        success: true,
        notificationToken: response.data!.notificationToken,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error finalising acceptance',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        FinaliseAcceptanceException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
