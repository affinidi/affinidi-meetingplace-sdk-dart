import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'accept_offer.dart';
import 'accept_offer_exception.dart';
import 'accept_offer_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Accept Offer
/// operation.
class AcceptOfferHandler
    implements CommandHandler<AcceptOfferCommand, AcceptOfferCommandOutput> {
  /// Returns an instance of [AcceptOfferHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of control plane api client object.
  AcceptOfferHandler({
    required this.apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'AcceptOfferHandler';

  final ControlPlaneApiClient apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Accept offer command object.
  ///
  /// **Returns:**
  /// - [AcceptOfferCommandOutput]: The accept offer command output object.
  ///
  /// **Throws:**
  /// - [AcceptOfferException]: Exception thrown by the accept offer handler.
  @override
  Future<AcceptOfferCommandOutput> handle(AcceptOfferCommand command) async {
    final methodName = 'handle';
    _logger.info('Started accepting offer', name: methodName);

    final builder = AcceptOfferInputBuilder()
      ..mnemonic = command.mnemonic
      ..did = command.acceptOfferDid
      ..deviceToken = command.device.deviceToken
      ..platformType = AcceptOfferInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      )
      ..offerLink = command.offerLink
      ..vcard = command.vCard.toBase64();

    Response<AcceptOfferOK> response;
    try {
      _logger.info(
        '[MPX API] Calling /accept-offer endpoint with mnemonic: ${command.mnemonic}',
        name: methodName,
      );
      response = await apiClient.client.acceptOfferToConnect(
        acceptOfferInput: builder.build(),
      );

      _logger.info('Completed accepting offer', name: methodName);
      return AcceptOfferCommandOutput(
        offerName: response.data!.name,
        offerLink: response.data!.offerLink,
        offerDescription: response.data!.description,
        didcommMessage: response.data!.didcommMessage,
        validUntil: response.data?.validUntil != null
            ? DateTime.parse(response.data!.validUntil!)
            : null,
        maximumUsage: response.data!.maximumUsage,
        mediatorDid: response.data!.mediatorDid,
      );
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.conflict) {
        _logger.error(
          '[MPX API] Offer already accepted (HTTP 409 Conflict)',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
        throw AcceptOfferException.alreadyAcceptedError(innerException: e);
      }

      if ((e.response?.data as Map<String, dynamic>?)?['name'] ==
          'OfferLimitExceededError') {
        _logger.error(
          '[MPX API] Offer limit exceeded error',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
        throw AcceptOfferException.limitExceededError();
      }

      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to accept offer',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        AcceptOfferException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
