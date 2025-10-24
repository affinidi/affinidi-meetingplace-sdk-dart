import 'package:dio/dio.dart';

/// A [Dio] interceptor class that intercepts and modifies the HTTP requests
/// after it receives an error from the API server.
class RetryInterceptor extends Interceptor {
  /// Create an instance of the [RetryInterceptor] Dio
  /// interceptor class.
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  /// Method that overrides the [Dio's onError] interceptor.
  ///
  /// This method is called whenever a request encounters an error. It is
  /// responsible for handling retries of failed requests to the API server.
  ///
  /// **Parameters:**
  /// - [err]: The DioException error to evaluate for retry.
  /// - [handler]: The error interceptor handler object.
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var retryCount = 0;

    if (_shouldRetry(err)) {
      while (retryCount < maxRetries) {
        try {
          retryCount++;

          await Future<void>.delayed(retryDelay * retryCount);

          final response = await dio.request<dynamic>(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );

          return handler.resolve(response);
        } on DioException catch (e) {
          if (retryCount >= maxRetries) {
            return handler.next(e);
          }
        }
      }
    }

    return handler.next(err);
  }

  /// A private method which evaluates the type of error that can be retried.
  ///
  /// **Parameter:**
  /// - [error]: The DIO exception.
  ///
  /// **Returns:**
  /// - [bool] Boolean value which indicates if the error should be retried.
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
