import 'dart:io';
import 'package:dio/dio.dart';

import '../../meeting_place_control_plane.dart';
import '../constants/sdk_constants.dart';
import 'auth_credentials.dart';

/// A [Dio] interceptor class that intercepts and modifies the HTTP requests
/// before sending it to the API server.
class RefreshAuthCredentialsInterceptor extends Interceptor {
  /// Create an instance of the [RefreshAuthCredentialsInterceptor] Dio
  /// interceptor class.
  RefreshAuthCredentialsInterceptor({
    required this.dio,
    required this.controlPlaneSDK,
    required this.controlPlaneDid,
    ControlPlaneSDKLogger? logger,
  }) : _logger = logger ??
            DefaultControlPlaneSDKLogger(
              className: _className,
              sdkName: sdkName,
            );

  static const String _className = 'RefreshAuthCredentialsInterceptor';

  final Dio dio;
  final ControlPlaneSDK controlPlaneSDK;
  final String controlPlaneDid;
  final ControlPlaneSDKLogger _logger;

  AuthCredentials? _authCredentials;

  /// Method that overrides the [Dio's onRequest] interceptor.
  ///
  /// This method handles the inclusion of authorization headers before sending
  /// the request to the API server.
  ///
  /// **Parameters:**
  /// - [options]: The requestOptions object.
  /// - [handler]: The interceptor handler object.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final methodName = 'onRequest';
    _logger.info('Started processing request', name: methodName);

    if (options.extra['secure'] == null || options.extra['secure'].isEmpty) {
      _logger.info(
        'Public endpoint, authentication handling not required',
        name: methodName,
      );
      super.onRequest(options, handler);
      return;
    }

    if (_authCredentials != null &&
        _isTokenValid(_authCredentials!.accessExpiresAt)) {
      _logger.info(
        'Existing access token is valid, reusing token',
        name: methodName,
      );
      super.onRequest(options, handler);
      return;
    }

    final refreshedAccessToken = await _refreshToken();
    options.headers['Authorization'] = 'Bearer $refreshedAccessToken';

    super.onRequest(options, handler);
    _logger.info('Completed processing request', name: methodName);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetryAuth = err.requestOptions.extra['retry_auth'] ?? true;

    if (err.response?.statusCode == HttpStatus.unauthorized &&
        err.response?.data['errorCode'] == 'AUTHORIZATION_TOKEN_EXPIRED' &&
        shouldRetryAuth == true) {
      try {
        _logger.info(
          '''Authorization token expired — attempting to refresh access token.''',
        );
        final refreshedAccessToken = await _refreshToken();

        final RequestOptions options = err.requestOptions;

        options.headers['Authorization'] = 'Bearer $refreshedAccessToken';
        options.extra['retry_auth'] = false;

        _logger.info('Retry request with refreshed access token');
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        _logger.error('Retry failed', error: e);
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String> _refreshToken() async {
    _logger.info('Refresh access token', name: 'refreshToken');

    final authenticationResult = await controlPlaneSDK.execute(
      AuthenticateCommand(controlPlaneDid: controlPlaneDid),
    );

    _authCredentials = authenticationResult.credentials;
    return authenticationResult.credentials.accessToken;
  }

  /// A private method that validates if the token is still valid.
  ///
  /// **Parameters:**
  /// - [expiresAt]: The token expiration in DateTime.
  /// - [bufferMinutes]: The buffer added in minutes. Default value is 2 if not
  /// provided.
  ///
  /// **Returns:**
  /// - [bool]: returns the boolean value.
  bool _isTokenValid(DateTime? expiresAt, {int bufferMinutes = 2}) {
    if (expiresAt == null) return false;

    final now = DateTime.now().toUtc();
    return expiresAt.isAfter(now.add(Duration(minutes: bufferMinutes)));
  }
}
