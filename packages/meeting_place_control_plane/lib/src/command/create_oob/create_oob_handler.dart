import 'dart:async';

import '../../api/api_client.dart';
import 'package:ssi/ssi.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/base64.dart';
import '../../utils/mediator/mediator_utils.dart';
import '../../utils/string.dart';
import 'create_oob.dart';
import 'create_oob_exception.dart';
import 'create_oob_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Create Out-Of-Band
/// operation.
class CreateOobHandler
    implements CommandHandler<CreateOobCommand, CreateOobCommandOutput> {
  /// Returns an instance of [CreateOobHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  /// - [mediatorDid] - The mediator did string.
  /// - [didResolver] - The did resolver object.
  CreateOobHandler({
    required ControlPlaneApiClient apiClient,
    required this.mediatorDid,
    required this.didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'CreateOobHandler';

  final ControlPlaneApiClient _apiClient;
  final String mediatorDid;
  final DidResolver didResolver;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Create OOB command object.
  ///
  /// **Returns:**
  /// - [CreateOobCommandOutput]: The create oob command output object.
  ///
  /// **Throws:**
  /// - [CreateOobException]: Exception thrown by the create oob handler.
  @override
  Future<CreateOobCommandOutput> handle(CreateOobCommand command) async {
    final methodName = 'handle';
    _logger.info('Started creating oob invitation', name: methodName);

    final defaultMediatorConfig = await MediatorUtils.resolveMediator(
      mediatorDid,
      didResolver: didResolver,
    );

    final mediatorConfig = command.mediatorDid != null
        ? await MediatorUtils.resolveMediator(
            command.mediatorDid!,
            didResolver: didResolver,
          )
        : null;

    final mediatorForOffer = mediatorConfig ?? defaultMediatorConfig;

    final builder = CreateOobInputBuilder()
      ..didcommMessage = toBase64(command.oobInvitationMessage.toJson())
      ..mediatorDid = mediatorForOffer.mediatorDid
      ..mediatorEndpoint = mediatorForOffer.mediatorEndpoint
      ..mediatorWSSEndpoint = mediatorForOffer.mediatorWSSEndpoint;

    try {
      _logger.info(
        '[MPX API] Calling /create-oob with mediatorDid: ${builder.mediatorDid?.topAndTail()} and mediatorEndpoint: ${builder.mediatorEndpoint}',
        name: methodName,
      );

      final response = await _apiClient.client.createOOB(
        createOobInput: builder.build(),
      );

      _logger.info(
        'Completed creating oob invitation with id: ${response.data!.oobId}',
        name: methodName,
      );
      return CreateOobCommandOutput(
        oobId: response.data!.oobId,
        oobUrl: response.data!.oobUrl,
        mediatorDid: mediatorForOffer.mediatorDid,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create oob invitation: ',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        CreateOobException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
