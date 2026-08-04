//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'serializers.dart';
import 'auth/api_key_auth.dart';
import 'auth/basic_auth.dart';
import 'auth/bearer_auth.dart';
import 'auth/oauth.dart';
import 'api/default_api.dart';

String _formatResponseError(int? statusCode, Object? errorData) {
  final buffer = StringBuffer('HTTP $statusCode Error\n');

  if (errorData is Map) {
    final errorMap = Map<String, dynamic>.from(errorData);
    final errorName = errorMap['name'] ?? 'Unknown Error';
    final traceId = errorMap['traceId']?.toString().isNotEmpty == true
        ? errorMap['traceId']
        : 'N/A';
    final errorMessage = errorMap['message'] ?? 'No error message provided';
    final details = errorMap['details'] != null
        ? errorMap['details'].toString()
        : 'No details available';

    buffer.write('- Error Type: $errorName\n');
    buffer.write('- Trace ID: $traceId\n');
    buffer.write('- Message: $errorMessage\n');
    buffer.write('- Details: $details\n');
    buffer.write('Response Body: ${jsonEncode(errorMap)}');
    return buffer.toString();
  }

  buffer.write('Response Body: ${errorData?.toString() ?? "No response body"}');
  return buffer.toString();
}

class ControlPlaneApi {
  final Dio dio;
  final Serializers serializers;

  ControlPlaneApi({
    Dio? dio,
    Serializers? serializers,
    required String basePath,
    List<Interceptor>? interceptors,
    Future<String?> Function()? authTokenHook,
  }) : this.serializers = serializers ?? standardSerializers,
       this.dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: basePath,
               connectTimeout: const Duration(milliseconds: 15000),
               receiveTimeout: const Duration(milliseconds: 15000),
             ),
           ) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }

    if (authTokenHook != null) {
      final authTokenInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Retrieve the auth token asynchronously, and set it in headers
            final token = await authTokenHook();
            options.headers['Authorization'] = 'Bearer $token';
          } catch (e) {
            // ignore: avoid_print
            print("Error retrieving auth token: $e");
          }
          // Continue with the request
          handler.next(options);
        },
      );

      // Add the authTokenInterceptor to Dio
      this.dio.interceptors.add(authTokenInterceptor);
    }

    // NOTE: global error-handling interceptor
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response != null) {
            final statusCode = e.response?.statusCode;
            final errorData = e.response?.data;
            final formattedError = _formatResponseError(statusCode, errorData);

            handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: formattedError,
              ),
            );
          } else {
            handler.next(e);
          }
        },
      ),
    );
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
                  as OAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
                  as BearerAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(
        username,
        password,
      );
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
                    (element) => element is ApiKeyAuthInterceptor,
                  )
                  as ApiKeyAuthInterceptor)
              .apiKeys[name] =
          apiKey;
    }
  }

  /// Get DefaultApi instance, base route and serializer can be overridden by a
  /// given but be careful,
  /// by doing that all interceptors will not be executed
  DefaultApi getDefaultApi() {
    return DefaultApi(dio, serializers);
  }
}
