import 'dart:async';

import '../../api/api_client.dart';
import 'package:dio/dio.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'accept_offer_group.dart';
import 'accept_offer_group_exception.dart';
import 'accept_offer_group_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Accept Offer Group
/// operation.
class AcceptOfferGroupHandler
    implements
        CommandHandler<AcceptOfferGroupCommand, AcceptOfferGroupCommandOutput> {
  /// Returns an instance of [AcceptOfferGroupHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  AcceptOfferGroupHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'AcceptOfferGroupHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Accept offer group command object.
  ///
  /// **Returns:**
  /// - [AcceptOfferGroupCommandOutput]: The accept offer group command
  /// output object.
  ///
  /// **Throws:**
  /// - [AcceptOfferGroupException]: Exception thrown by the accept offer
  /// handler.
  @override
  Future<AcceptOfferGroupCommandOutput> handle(
    AcceptOfferGroupCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started accepting offer group', name: methodName);

    final builder = AcceptOfferGroupInputBuilder()
      ..mnemonic = command.mnemonic
      ..did = command.acceptOfferDid
      ..deviceToken = command.device.deviceToken
      ..platformType = AcceptOfferGroupInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      )
      ..offerLink = command.offerLink
      ..contactCard = command.contactCard.toBase64();

    Response<AcceptOfferGroupOK> response;
    try {
      _logger.info(
        '[MPX API] Calling /accept-offer with mnemonic: ${command.mnemonic}',
        name: methodName,
      );
      response = await _apiClient.client.acceptOfferToConnectGroup(
        acceptOfferGroupInput: builder.build(),
      );

      _logger.info('Completed accepting offer group', name: methodName);
      return AcceptOfferGroupCommandOutput(
        offerLink: response.data!.offerLink,
        didcommMessage: response.data!.didcommMessage,
        validUntil: response.data?.validUntil != null
            ? DateTime.parse(response.data!.validUntil!)
            : null,
        mediatorDid: response.data!.mediatorDid,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to accept offer group',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        AcceptOfferGroupException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
