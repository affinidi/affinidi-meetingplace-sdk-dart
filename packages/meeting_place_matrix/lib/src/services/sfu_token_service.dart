import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart';

import '../../meeting_place_matrix.dart';
import '../models/sfu_token_response.dart';

/// Exchanges a Matrix OpenID token for a LiveKit JWT via the lk-jwt-service
/// `POST /sfu/get` endpoint.
class SfuTokenService {
  SfuTokenService({
    required Uri serviceUrl,
    Dio? dio,
    MeetingPlaceMatrixSDKLogger? logger,
  }) : _serviceUrl = serviceUrl,
       _dio = dio ?? Dio(),
       _logger =
           logger ??
           DefaultMeetingPlaceMatrixSDKLogger(className: 'SfuTokenService');

  final Uri _serviceUrl;
  final Dio _dio;
  final MeetingPlaceMatrixSDKLogger _logger;

  /// Fetches a LiveKit JWT for [roomName] using [openIdCredentials].
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] if the request fails
  /// or the response is missing the required `token` field.
  Future<SfuTokenResponse> fetchToken({
    required String roomName,
    required OpenIdCredentials openIdCredentials,
    String? deviceId,
  }) async {
    const methodName = 'fetchToken';
    _logger.info(
      'Fetching token for room=$roomName deviceId=$deviceId',
      name: methodName,
    );
    final url = _serviceUrl.replace(path: '/sfu/get');
    try {
      final requestBody = <String, dynamic>{
        'room': roomName,
        'openid_token': {
          'access_token': openIdCredentials.accessToken,
          'token_type': openIdCredentials.tokenType,
          'matrix_server_name': openIdCredentials.matrixServerName,
        },
      };
      if (deviceId != null && deviceId.isNotEmpty) {
        requestBody['device_id'] = deviceId;
      }
      final response = await _dio.postUri<Map<String, dynamic>>(
        url,
        data: requestBody,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      final body = response.data;
      if (body == null) {
        throw const MeetingPlaceLiveKitCallOperationException(
          'lk-jwt-service returned an empty response body',
        );
      }

      final token = body['jwt'] as String?;
      if (token == null || token.isEmpty) {
        throw const MeetingPlaceLiveKitCallOperationException(
          'lk-jwt-service response is missing the required "jwt" field',
        );
      }

      final sfuUrl = body['url'] as String?;
      _logger.info('Token received sfuUrl=$sfuUrl', name: methodName);
      return SfuTokenResponse(token: token, url: sfuUrl);
    } on MeetingPlaceLiveKitCallOperationException {
      rethrow;
    } on DioException catch (e, stackTrace) {
      _logger.error(
        'HTTP request failed',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      throw MeetingPlaceLiveKitCallOperationException(
        'HTTP request to lk-jwt-service failed: ${e.message}',
        innerException: e,
      );
    }
  }
}
