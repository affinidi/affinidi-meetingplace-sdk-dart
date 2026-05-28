import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../core/didcomm/didcomm_challenge_response.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'matrix_media_download.dart';
import 'matrix_media_download_exception.dart';
import 'matrix_media_download_output.dart';

class MatrixMediaDownloadHandler
    implements
        CommandHandler<
          MatrixMediaDownloadCommand,
          MatrixMediaDownloadCommandOutput
        > {
  MatrixMediaDownloadHandler({
    required this.apiClient,
    required this.didResolver,
    required this.controlPlaneDid,
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(className: _logKey, sdkName: sdkName);

  static const String _logKey = 'MatrixMediaDownloadHandler';

  final ControlPlaneApiClient apiClient;
  final DidResolver didResolver;
  final String controlPlaneDid;
  final ControlPlaneSDKLogger _logger;

  String _parseDownloadUrl(Map<String, dynamic>? data) {
    if (data == null) {
      _logger.error('Response data is null', name: _logKey);
      throw MatrixMediaDownloadException.invalidResponse(
        message: 'Response data is null',
      );
    }

    final url = data['url'];
    if (url is! String || url.trim().isEmpty) {
      _logger.error('Missing or empty url in response', name: _logKey);
      throw MatrixMediaDownloadException.invalidResponse(
        message: 'Missing or empty url in response',
      );
    }

    return url;
  }

  Uint8List _parseBytes(dynamic data) {
    if (data is Uint8List) {
      return data;
    }

    if (data is List<int>) {
      return Uint8List.fromList(data);
    }

    if (data is List && data.every((item) => item is int)) {
      return Uint8List.fromList(data.cast<int>());
    }

    throw MatrixMediaDownloadException.invalidResponse(
      message: 'Invalid media download response payload',
    );
  }

  MatrixMediaDownloadException _mapDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final retryAfterHeader = exception.response?.headers.value('retry-after');
    final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');

    return switch (statusCode) {
      403 => MatrixMediaDownloadException.forbidden(innerException: exception),
      404 => MatrixMediaDownloadException.notFound(innerException: exception),
      429 => MatrixMediaDownloadException.rateLimited(
        retryAfterSeconds: retryAfterSeconds,
        innerException: exception,
      ),
      _ => MatrixMediaDownloadException.generic(innerException: exception),
    };
  }

  @override
  Future<MatrixMediaDownloadCommandOutput> handle(
    MatrixMediaDownloadCommand command,
  ) async {
    try {
      final challengeResponse = await DidCommChallengeResponse.build(
        apiClient: apiClient,
        didManager: command.didManager,
        didResolver: didResolver,
        recipientDid: controlPlaneDid,
        challengeProvider: DidCommChallengeResponse.matrixChallengeProvider(
          apiClient.dio,
        ),
        onEmptyChallenge: (_) {
          _logger.error(
            'Empty challenge returned from matrix challenge',
            name: _logKey,
          );
          return MatrixMediaDownloadException.invalidResponse(
            message: 'Empty challenge returned from matrix challenge',
          );
        },
      );

      final urlResponse = await apiClient.dio.post<Map<String, dynamic>>(
        '/v1/matrix/media/download-url',
        data: {
          'challenge_response': challengeResponse.challengeResponse,
          'homeserver': command.homeserver.toString(),
          'room_id': command.roomId,
          'media_uri': command.mxcUri,
        },
        options: Options(
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
          contentType: Headers.jsonContentType,
        ),
      );

      final downloadUrl = _parseDownloadUrl(urlResponse.data);

      final mediaResponse = await apiClient.dio.get<dynamic>(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      return MatrixMediaDownloadCommandOutput(
        bytes: _parseBytes(mediaResponse.data),
      );
    } on DioException catch (e, stackTrace) {
      _logger.error(
        'Failed to download Matrix media',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );

      Error.throwWithStackTrace(_mapDioException(e), stackTrace);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to download Matrix media',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );

      Error.throwWithStackTrace(
        e is MatrixMediaDownloadException
            ? e
            : MatrixMediaDownloadException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
