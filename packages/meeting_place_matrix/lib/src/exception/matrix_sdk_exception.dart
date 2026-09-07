import 'dart:async';
import 'dart:io';

import '../meeting_place_matrix_sdk_error_code.dart';

/// Base exception interface for all Matrix SDK errors.
abstract interface class MeetingPlaceMatrixSDKException implements Exception {
  /// Human-readable description of the failure.
  String get message;

  /// The specific error this exception represents.
  MeetingPlaceMatrixSDKErrorCode get code;

  /// The underlying error that caused this exception, if any.
  Object? get innerException;
}

/// Helpers for classifying an [Exception] without knowing its concrete type.
extension ExceptionExtentions on Exception {
  /// Whether this exception represents a network-level failure (socket,
  /// timeout, HTTP, or TLS/handshake error) rather than an application error.
  bool get isNetworkError {
    return this is SocketException ||
        this is TimeoutException ||
        this is HttpException ||
        this is HandshakeException ||
        this is TlsException;
  }
}
