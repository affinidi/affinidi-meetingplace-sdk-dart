import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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
      Response<dynamic> response;

      Future<Response<dynamic>> doRequest({
        Map<String, dynamic>? headers,
        required String path,
      }) {
        return _apiClient.dio.post<dynamic>(
          path,
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
            responseType: ResponseType.plain,
          ),
        );
      }

      try {
        response = await doRequest(path: '/v1/matrix/token');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final token =
            e.requestOptions.headers['authorization'] ??
            e.requestOptions.headers['Authorization'];

        // Backward compatibility: older Control Plane servers expose the
        // matrix credential endpoint under /api/did/matrix-registration-credential.
        if (status == 404) {
          response = await doRequest(
            headers: token is String ? {'Authorization': 'Bearer $token'} : null,
            path: '/api/did/matrix-registration-credential',
          );
          // Continue with common parsing/validation below.
          return _parseResponse(response);
        }

        // Upstream API prefers Bearer auth; retry once if we likely sent the
        // raw token (apiKey style) and were rejected.
        if ((status == 401 || status == 403) && token is String) {
          response = await doRequest(
            headers: {'Authorization': 'Bearer $token'},
            path: '/v1/matrix/token',
          );
        } else {
          rethrow;
        }
      }

      return _parseResponse(response);
    } on MatrixRegistrationCredentialException {
      rethrow;
    } on DioException catch (e) {
      throw MatrixRegistrationCredentialException.generic(
        message:
            'Failed to fetch Matrix registration credential. status=${e.response?.statusCode}, body=${e.response?.data}',
        innerException: e,
      );
    } catch (e) {
      throw MatrixRegistrationCredentialException.generic(
        message: 'Failed to fetch Matrix registration credential',
        innerException: e,
      );
    }
  }

  MatrixRegistrationCredentialCommandOutput _parseResponse(
    Response<dynamic> response,
  ) {
    try {
      final data = _toMap(response.data);
      if (data == null) {
        throw MatrixRegistrationCredentialException.invalidResponse(
          message:
              'Response data is not valid JSON object. status=${response.statusCode}, body=${response.data}',
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

      String? matrixLocalpart;
      try {
        final claims = JWT.decode(credential).payload;
        final sub = claims['sub'];
        if (sub is String && sub.trim().isNotEmpty) {
          matrixLocalpart = sub.trim();
        }
      } catch (_) {
        // Non-fatal: credential signature validation happens on Synapse side.
      }

      return MatrixRegistrationCredentialCommandOutput(
        credential: credential,
        did: did,
        matrixLocalpart: matrixLocalpart,
      );
    } on MatrixRegistrationCredentialException {
      rethrow;
    } catch (e) {
      throw MatrixRegistrationCredentialException.generic(
        message:
            'Failed to parse Matrix registration credential response. status=${response.statusCode}, body=${response.data}',
        innerException: e,
      );
    }
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    }
    return null;
  }
}
