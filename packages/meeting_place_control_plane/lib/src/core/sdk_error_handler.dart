import 'package:dio/dio.dart';

import '../../meeting_place_control_plane.dart';
import 'exception/control_plane_exception.dart';
import '../utils/string.dart';

class SDKErrorHandler {
  SDKErrorHandler(
      {required ControlPlaneSDKLogger logger, required this.controlPlaneDid})
      : _logger = logger;

  final ControlPlaneSDKLogger _logger;
  final String controlPlaneDid;

  final _networkErrorTypes = [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  ];

  Future<T> handleError<T>(Future<T> Function() operation) async {
    final methodName = 'handleError';
    try {
      return await operation();
    } on ControlPlaneException catch (e, stackTrace) {
      _logger.error(
        'Control plane exception - control plane DID: ${controlPlaneDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        ControlPlaneSDKException(
          message: e.message,
          code: e.code.value,
          innerException: e.innerException ?? e,
        ),
        stackTrace,
      );
    } on DioException catch (e, stackTrace) {
      _logger.error(
        'Control Plane network exception - control plane DID: ${controlPlaneDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );

      if (!_networkErrorTypes.contains(e.type)) {
        Error.throwWithStackTrace(
          ControlPlaneSDKException(
            message: e.toString(),
            code: ControlPlaneSDKErrorCode.generic.value,
            innerException: e,
          ),
          stackTrace,
        );
      }

      Error.throwWithStackTrace(
        ControlPlaneSDKException(
          message: e.toString(),
          code: ControlPlaneSDKErrorCode.networkError.value,
          innerException: e,
        ),
        stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Control plane exception - control plane DID: ${controlPlaneDid.topAndTail()}',
        error: e,
        stackTrace: stackTrace,
        name: '_throwGeneric',
      );
      Error.throwWithStackTrace(
        ControlPlaneSDKException(
          message: e.toString(),
          code: ControlPlaneSDKErrorCode.generic.value,
          innerException: e,
        ),
        stackTrace,
      );
    }
  }
}
