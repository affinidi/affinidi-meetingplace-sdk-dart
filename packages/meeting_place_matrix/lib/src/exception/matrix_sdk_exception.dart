import 'dart:async';
import 'dart:io';

import '../meeting_place_matrix_sdk_error_code.dart';

/// Base exception interface for all Matrix SDK errors.
abstract interface class MatrixSDKException implements Exception {
  String get message;
  MeetingPlaceMatrixSDKErrorCode get code;
  Object? get innerException;
}

extension ExceptionExtentions on Exception {
  bool get isNetworkError {
    return this is SocketException ||
        this is TimeoutException ||
        this is HttpException ||
        this is HandshakeException ||
        this is TlsException;
  }
}
