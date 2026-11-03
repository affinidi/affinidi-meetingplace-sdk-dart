import 'dart:convert';

import 'package:dio/dio.dart';

import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../trust_task/trust_task_document.dart';

/// Marker in the type URI of a Trust Task error document.
const _trustTaskErrorMarker = '/trust-task-error/';

/// Sends Trust Task documents over the HTTPS binding: a `POST` of the signed
/// document to `<base>/trust-tasks`.
///
/// No `Origin` header is sent: a VTC accepts browser-originated requests only
/// from its own portal, and the wallet is not a browser. Error documents are
/// read as answers whatever the HTTP status.
class TrustTaskHttpTransport {
  /// Creates a [TrustTaskHttpTransport] that sends with [dio].
  TrustTaskHttpTransport({Dio? dio}) : _dio = dio ?? Dio();

  /// How long one task may take, end to end.
  static const timeout = Duration(seconds: 40);

  final Dio _dio;

  /// Posts [document] to [base] and returns the answer.
  ///
  /// [bearerToken] authorises the request where the service requires it.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.refused] and the full refusal code when the
  /// service answers with a Trust Task error, or
  /// [MeetingPlaceVtcSDKErrorCode.transportFailed] when there is no usable
  /// answer.
  Future<TrustTaskDocument> send(
    Uri base,
    TrustTaskDocument document, {
    String? bearerToken,
  }) async {
    final Response<String> response;
    try {
      response = await _dio.postUri<String>(
        _trustTasksUri(base),
        data: document.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
          headers: {'Authorization': ?_authorization(bearerToken)},
        ),
      );
    } on DioException catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        error.type.name,
        innerException: error,
      );
    }

    final body = _decode(response.data);
    final type = body is Map<String, dynamic> ? body['type'] : null;
    // A server error page or a framework's own JSON error, e.g. a 401 for a
    // lapsed token, is no Trust Task: keep its status so callers can act.
    if (body is! Map<String, dynamic> || type is! String) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'HTTP ${response.statusCode} without a document',
        httpStatus: response.statusCode,
      );
    }

    if (type.contains(_trustTaskErrorMarker)) {
      final payload = body['payload'];
      final errorPayload = payload is Map<String, dynamic> ? payload : null;
      final code = errorPayload?['code'];
      throw MeetingPlaceVtcSDKException.refused(
        code is String ? code : 'unknown',
        errorPayload: errorPayload,
        httpStatus: response.statusCode,
      );
    }
    return TrustTaskDocument.fromJson(body);
  }

  /// Fetches the JSON object at [uri], such as a community's public
  /// profile. Unlike an answer to [send], it is not signed.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.transportFailed] when there is no JSON
  /// object to read, with the HTTP status when there was an answer.
  Future<Map<String, dynamic>> fetchJson(Uri uri) async {
    final Response<String> response;
    try {
      response = await _dio.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        error.type.name,
        innerException: error,
      );
    }
    final body = _decode(response.data);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'HTTP ${response.statusCode} without a JSON object',
        httpStatus: response.statusCode,
      );
    }
    return body;
  }

  static Object? _decode(String? text) {
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static Uri _trustTasksUri(Uri base) {
    final path = base.path.replaceAll(RegExp(r'/+$'), '');
    return base.replace(path: '$path/trust-tasks');
  }

  static String? _authorization(String? bearerToken) =>
      bearerToken == null ? null : 'Bearer $bearerToken';
}
