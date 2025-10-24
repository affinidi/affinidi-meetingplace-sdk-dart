import '../../api/api_client.dart';
import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_dispatcher.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import 'validate_offer_phrase.dart';
import 'validate_offer_phrase_exception.dart';
import 'validate_offer_phrase_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Validate Offer
/// Phrase operation.
class ValidateOfferPhraseHandler
    implements
        CommandHandler<ValidateOfferPhraseCommand,
            ValidateOfferPhraseCommandOutput> {
  /// Returns an instance of [ValidateOfferPhraseHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  /// - [dispatcher] - The command dispather object.
  /// - [logger] - An instance of logger object.
  ValidateOfferPhraseHandler({
    required ControlPlaneApiClient apiClient,
    required CommandDispatcher dispatcher,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'ValidateOfferPhraseHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Validate offer phrase command object.
  ///
  /// **Returns:**
  /// - [ValidateOfferPhraseCommandOutput]: The validate offer phrase command
  /// output object.
  ///
  /// **Throws:**
  /// - [ValidateOfferPhraseExceptions]: Exception thrown by the validate offer
  /// phrase operation.
  @override
  Future<ValidateOfferPhraseCommandOutput> handle(
    ValidateOfferPhraseCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Started validating offer phrase: ${command.phrase}',
      name: methodName,
    );
    try {
      final builder = CheckOfferPhraseInputBuilder()
        ..offerPhrase = command.phrase;

      _logger.info(
        '[MPX API] Calling /check-offer-phrase for phrase: ${command.phrase}',
        name: methodName,
      );
      final response = await _apiClient.client.checkOfferPhrase(
        checkOfferPhraseInput: builder.build(),
      );

      _logger.info(
        'Completed validating offer phrase: ${command.phrase}',
        name: methodName,
      );
      return ValidateOfferPhraseCommandOutput(
        isAvailable: response.data?.isInUse == false,
      );
    } on DioException catch (dioException, stackTrace) {
      final exceptionType = dioException.type;
      final statusCode = dioException.response?.statusCode;

      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ].contains(exceptionType)) {
        _logger.error(
          '[MPX API] Timeout occurred while validating offer phrase: ${command.phrase}',
          error: dioException,
          stackTrace: stackTrace,
          name: methodName,
        );
        throw ValidateOfferPhraseExceptions.timeout(
          innerException: dioException,
        );
      } else if (exceptionType == DioExceptionType.badResponse) {
        if (statusCode == 429) {
          _logger.error(
            '[MPX API] Rate limit exceeded while validating offer phrase: ${command.phrase}',
            error: dioException,
            stackTrace: stackTrace,
            name: methodName,
          );
          throw ValidateOfferPhraseExceptions.rateLimit(
            innerException: dioException,
          );
        } else if (statusCode == 401 || statusCode == 403) {
          _logger.error(
            '[MPX API] Authentication error while validating offer phrase: ${command.phrase}',
            error: dioException,
            stackTrace: stackTrace,
            name: methodName,
          );
          throw ValidateOfferPhraseExceptions.authentication(
            innerException: dioException,
          );
        }
      }

      _logger.error(
        '[MPX API] Error validating offer phrase: ${command.phrase}',
        error: dioException,
        stackTrace: stackTrace,
        name: methodName,
      );
      throw ValidateOfferPhraseExceptions.generic(innerException: dioException);
    } catch (e, s) {
      _logger.error(
        'Error validating offer phrase',
        error: e,
        stackTrace: s,
        name: methodName,
      );
      throw ValidateOfferPhraseExceptions.generic(innerException: e);
    }
  }
}
