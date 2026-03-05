import 'dart:async';
import 'dart:io';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

class ErrorHandlerUtils {
  static bool isRetryableError(Object? e) {
    return e is SsiException && e.code == SsiExceptionType.invalidDidWeb.code ||
        e is MediatorClientException && _isNetworkError(e.error) ||
        _isNetworkError(e);
  }

  static bool _isNetworkError(Object? e) {
    return e is SocketException ||
        e is TimeoutException ||
        e is HttpException ||
        e is HandshakeException ||
        e is TlsException;
  }
}
