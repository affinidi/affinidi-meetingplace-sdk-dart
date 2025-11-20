import 'dart:async';

import 'package:ssi/ssi.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'get_oob.dart';
import 'get_oob_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Get Out-Of-Band
///  operation.
class GetOobHandler
    implements CommandHandler<GetOobCommand, GetOobCommandOutput> {
  /// Returns an instance of [GetOobHandler].
  ///
  /// **Parameters:**
  /// - `mpxClient` - An instance of discovery api client object.
  /// - `mediatorDid` - The mediator did string.
  /// - `didResolver` - The did resolver object.
  GetOobHandler({
    required ControlPlaneApiClient apiClient,
    required this.mediatorDid,
    required this.didResolver,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'GetOobHandler';

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
  /// - [command]: Get Out-Of-Band command object.
  ///
  /// **Returns:**
  /// - [GetOobCommandOutput]: The get Out-Of-Band command
  /// output object.
  @override
  Future<GetOobCommandOutput> handle(GetOobCommand command) async {
    final methodName = 'handle';
    _logger.info('Started getting OOB', name: methodName);

    _logger.info(
      '[MPX API] Calling /get-oob for oobId: ${command.oobId}',
      name: methodName,
    );
    final response = await _apiClient.client.getOOB(
      oobId: command.oobId,
    );

    _logger.info(
      'Completed getting OOB: '
      'oobId: ${command.oobId}, '
      'mediatorDid: ${response.data?.mediatorDid}, '
      'mediatorEndpoint: ${response.data?.mediatorEndpoint}, '
      'mediatorWSSEndpoint: ${response.data?.mediatorWSSEndpoint}',
      name: methodName,
    );
    return GetOobCommandOutput(
      invitationMessage: response.data!.didcommMessage,
      mediatorDid: response.data!.mediatorDid,
    );
  }
}
