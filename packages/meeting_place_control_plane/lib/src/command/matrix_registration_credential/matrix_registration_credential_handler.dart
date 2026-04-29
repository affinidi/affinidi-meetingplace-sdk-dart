import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'matrix_registration_credential.dart';
import 'matrix_registration_credential_exception.dart';
import 'matrix_registration_credential_output.dart';

/// Calls the Control Plane endpoint to obtain a Matrix registration credential.
///
/// Preferred flow (supported by the Control Plane API):
/// - Use an existing Bearer access token (handled by interceptors) and only
///   send the target `homeserver`.
class MatrixRegistrationCredentialHandler
    implements
        CommandHandler<
          MatrixRegistrationCredentialCommand,
          MatrixRegistrationCredentialCommandOutput
        > {
  MatrixRegistrationCredentialHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'MatrixRegistrationCredentialHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<MatrixRegistrationCredentialCommandOutput> handle(
    MatrixRegistrationCredentialCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Fetching Matrix registration credential for homeserver=${command.homeserver}',
      name: methodName,
    );

    try {
      Response<Map<String, dynamic>> response;

      Future<Response<Map<String, dynamic>>> doRequest({
        Map<String, dynamic>? headers,
      }) {
        return _apiClient.dio.post<Map<String, dynamic>>(
          '/v1/matrix/token',
          data: {'homeserver': command.homeserver},
          options: Options(
            // Trigger RefreshAuthCredentialsInterceptor to attach/refresh token.
            extra: {
              'secure': [
                {
                  'type': 'apiKey',
                  'name': 'DidCommTokenAuth',
                  'keyName': 'authorization',
                  'where': 'header',
                },
              ],
            },
            headers: headers,
            contentType: Headers.jsonContentType,
          ),
        );
      }

      try {
        response = await doRequest();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final token =
            e.requestOptions.headers['authorization'] ??
            e.requestOptions.headers['Authorization'];

        // Upstream API prefers Bearer auth; retry once if we likely sent the
        // raw token (apiKey style) and were rejected.
        if ((status == 401 || status == 403) && token is String) {
          response = await doRequest(
            headers: {'Authorization': 'Bearer $token'},
          );
        } else {
          rethrow;
        }
      }

      final data = response.data;
      if (data == null) {
        throw MatrixRegistrationCredentialException.invalidResponse(
          message: 'Response data is null',
        );
      }

      final credential = data['credential'];
      final did = data['did'];
      if (credential is! String || credential.trim().isEmpty) {
        throw MatrixRegistrationCredentialException.invalidResponse(
          message: 'Missing or empty credential in response',
        );
      }
      if (did is! String || did.trim().isEmpty) {
        throw MatrixRegistrationCredentialException.invalidResponse(
          message: 'Missing or empty did in response',
        );
      }

      return MatrixRegistrationCredentialCommandOutput(
        credential: credential,
        did: did,
      );
    } on MatrixRegistrationCredentialException {
      rethrow;
    } catch (e) {
      throw MatrixRegistrationCredentialException.generic(
        message: 'Failed to fetch Matrix registration credential',
        innerException: e,
      );
    }
  }
}
