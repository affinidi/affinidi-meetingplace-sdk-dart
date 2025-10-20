import 'dart:async';
import 'dart:io';
import '../../api/api_client.dart';
import 'package:dio/dio.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_dispatcher.dart';
import '../../core/command/command_handler.dart';
import '../../core/offer_type.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../protocol/message/oob_invitation_message.dart';
import '../../protocol/v_card/v_card_impl.dart';
import 'query_offer.dart';
import 'query_offer_exception.dart';
import 'query_offer_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Query Offer
/// operation.
class QueryOfferHandler
    implements CommandHandler<QueryOfferCommand, QueryOfferCommandOutput> {
  /// Returns an instance of [QueryOfferHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  /// - [dispatcher] - An instance of command dispatcher object.
  QueryOfferHandler({
    required ControlPlaneApiClient apiClient,
    required this.dispatcher,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'QueryOfferHandler';

  final ControlPlaneApiClient _apiClient;
  final CommandDispatcher dispatcher;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: query offer command object.
  ///
  /// **Returns:**
  /// - [QueryOfferCommandOutput]: The query offer command output
  /// object.
  ///
  /// **Throws:**
  /// - [QueryOfferException]: Exception thrown by the query offer
  /// operation.
  @override
  Future<QueryOfferCommandOutput> handle(QueryOfferCommand command) async {
    final methodName = 'handle';
    _logger.info('Started querying offer', name: methodName);

    final builder = QueryOfferInputBuilder()..mnemonic = command.mnemonic;

    try {
      _logger.info(
        '[MPX API] Calling /query-offer for mnemonic: ${command.mnemonic}',
        name: methodName,
      );
      final response = (await _apiClient.client.queryOffer(
        queryOfferInput: builder.build(),
      ))
          .data;

      if (response == null) {
        _logger.warning('Query offer returned null response', name: methodName);
        return NullQueryOfferCommandOutput();
      }

      _logger.info('Completed querying offer', name: methodName);
      return SuccessQueryOfferCommandOutput(
        offerLink: response.offerLink,
        offerName: response.name,
        offerDescription: response.description,
        type: OfferType.fromContactAttributes(response.contactAttributes),
        mnemonic: command.mnemonic,
        mediatorDid: response.mediatorDid,
        status: response.status,
        expiresAt: response.validUntil != null
            ? DateTime.parse(response.validUntil!)
            : null,
        maximumUsage: response.maximumUsage,
        vCard: VCardImpl.fromBase64(response.vcard),
        didcommMessage: OobInvitationMessage.fromBase64(
          response.didcommMessage,
        ),
        groupDid: response.groupDid,
        groupId: response.groupId,
      );
    } catch (e, stackTrace) {
      if (e is DioException && e.response!.statusCode == HttpStatus.notFound) {
        _logger.error(
          '[MPX API] Offer not found',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
        return NullQueryOfferCommandOutput();
      }

      _logger.error(
        'Failed to query offer',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        QueryOfferException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
