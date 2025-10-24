import 'package:dio/dio.dart';

/// [RetryInterceptor] used to intercept and handle HTTP requests by automatically retrying
/// failed requests based on specific conditions.
///
/// **Parameters:**
/// - [dio]: The Dio instance used to perform HTTP requests and retries.
/// - [maxRetries]: The maximum number of times a request will be retried after failure.
/// - [retryDelay]: The duration of wait between retry attempts.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  /// Sends a [DioException] message when error occurs during an HTTP request.
  ///
  /// **Parameters:**
  /// - [err]: Represents the error object that occured in the request.
  /// - [handler]: Allows controlling how to proceed with the error.
  /// It provides ways to continue error processing, retry the request,
  /// or resolve the error with custom handling.
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    var retryCount = requestOptions.extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      retryCount++;
      requestOptions.extra['retryCount'] = retryCount;

      final delay = retryDelay * (1 << (retryCount - 1));
      await Future<void>.delayed(delay);

      try {
        final response = await dio.fetch<dynamic>(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return super.onError(e, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
