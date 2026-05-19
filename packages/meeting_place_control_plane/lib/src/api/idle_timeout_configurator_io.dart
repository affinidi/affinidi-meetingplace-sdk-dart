import 'dart:io' show HttpClient;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureIdleTimeout(Dio dio, Duration idleTimeout) {
  if (dio.httpClientAdapter case final IOHttpClientAdapter adapter) {
    adapter.createHttpClient = () => HttpClient()..idleTimeout = idleTimeout;
  }
}
