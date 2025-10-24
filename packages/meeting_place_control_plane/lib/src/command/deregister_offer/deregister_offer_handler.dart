import 'dart:io';

import '../../api/api_client.dart';
import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'deregister_offer.dart';
import 'deregister_offer_exception.dart';
import 'deregister_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Deregister
/// Offer operation.
class DeregisterOfferHandler
    implements
        CommandHandler<DeregisterOfferCommand, DeregisterOfferCommandOutput> {
  /// Returns an instance of [DeregisterOfferHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  DeregisterOfferHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'DeregisterOfferHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Deregister offer command object.
  ///
  /// **Returns:**
  /// - [DeregisterOfferCommandOutput]: The deregister offer command
  /// output object.
  ///
  /// **Throws:**
  /// - [DeregisterOfferException]: Exception thrown by the deregister
  /// offer operation.
  @override
  Future<DeregisterOfferCommandOutput> handle(
    DeregisterOfferCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Started deregistering offer: ${command.offerLink}',
      name: methodName,
    );

    final builder = DeregisterOfferInputBuilder()
      ..offerLink = command.offerLink
      ..mnemonic = command.mnemonic;

    try {
      _logger.info('[MPX API] calling /deregister-offer', name: methodName);
      await _apiClient.client.deregisterOfferToConnect(
        deregisterOfferInput: builder.build(),
      );

      _logger.info(
        'Completed deregistering offer: ${command.offerLink}',
        name: methodName,
      );
      return DeregisterOfferCommandOutput(success: true);
    } on DeregisterOfferException {
      _logger.warning(
        'Deregister offer failed: ${command.offerLink}',
        name: methodName,
      );
      rethrow;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.conflict) {
        /// Note that here, if it is a conflict 409, we assume success and
        /// ignore, because this just means that the record was already
        /// deleted. No point in blocking the UX, and it is not an error.
        _logger.warning(
          '[MPX API] deregister returned 409 Conflict - offer already deregistered, treating as success',
          name: methodName,
        );
        return DeregisterOfferCommandOutput(success: true);
      }

      _logger.error(
        '[MPX API] Failed to deregister offer: ${command.offerLink}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(e, stackTrace);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to deregister offer: ${command.offerLink}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        DeregisterOfferException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
