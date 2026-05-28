import 'package:ssi/ssi.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../core/didcomm/didcomm_challenge_response.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'matrix_token.dart';
import 'matrix_token_exception.dart';
import 'matrix_token_output.dart';

/// A concrete implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including preparing the
/// challenge-response authentication payload, sending the request, and
/// validating the returned data for the Matrix token operation.
class MatrixTokenHandler
    implements CommandHandler<MatrixTokenCommand, MatrixTokenCommandOutput> {
  /// Returns an instance of [MatrixTokenHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of control plane api client object.
  /// - [didResolver] - The did resolver object.
  /// - [controlPlaneDid] - The control plane DID string.
  MatrixTokenHandler({
    required this.apiClient,
    required this.didResolver,
    required this.controlPlaneDid,
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(className: _logKey, sdkName: sdkName);

  static const String _logKey = 'MatrixTokenHandler';

  final ControlPlaneApiClient apiClient;
  final DidResolver didResolver;
  final String controlPlaneDid;
  final ControlPlaneSDKLogger _logger;

  MatrixTokenCommandOutput _parseResponseData(MatrixTokenOK? data) {
    if (data == null) {
      _logger.error('Response data is null', name: _logKey);
      throw MatrixTokenException.invalidResponse(
        message: 'Response data is null',
      );
    }

    final token = data.token;
    if (token == null || token.trim().isEmpty) {
      _logger.error('Missing or empty token in response', name: _logKey);
      throw MatrixTokenException.invalidResponse(
        message: 'Missing or empty token in response',
      );
    }

    return MatrixTokenCommandOutput(token: MatrixLoginToken.fromJwt(token));
  }

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exceptions returned by the
  /// API server.
  ///
  /// **Parameters:**
  /// - [command]: Matrix token command object.
  ///
  /// **Returns:**
  /// - [MatrixTokenCommandOutput]: The matrix token command output object.
  ///
  /// **Throws:**
  /// - [MatrixTokenException]: Exception thrown by the matrix token
  /// operation.
  @override
  Future<MatrixTokenCommandOutput> handle(MatrixTokenCommand command) async {
    try {
      final challengeResponse = await DidCommChallengeResponse.buildForMatrix(
        apiClient: apiClient,
        didManager: command.didManager,
        didResolver: didResolver,
        recipientDid: controlPlaneDid,
        onEmptyChallenge: (_) {
          _logger.error(
            'Empty challenge returned from matrixChallenge',
            name: _logKey,
          );
          return MatrixTokenException.invalidResponse(
            message: 'Empty challenge returned from matrixChallenge',
          );
        },
      );

      final response = await apiClient.client.matrixToken(
        matrixToken: (MatrixTokenBuilder()
              ..challengeResponse = challengeResponse.challengeResponse
              ..homeserver = command.homeserver.toString())
            .build(),
      );

      return _parseResponseData(response.data);
    } catch (e, stackTrace) {
      _logger.error(
        '''Failed to fetch Matrix login token for homeserver=${command.homeserver}''',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );

      Error.throwWithStackTrace(
        e is MatrixTokenException
            ? e
            : MatrixTokenException.generic(
                message: 'Failed to fetch Matrix login token',
                innerException: e,
              ),
        stackTrace,
      );
    }
  }
}
