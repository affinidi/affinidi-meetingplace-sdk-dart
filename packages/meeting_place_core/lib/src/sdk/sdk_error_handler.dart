import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';

import '../exception/sdk_exception.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../meeting_place_core_sdk_exception.dart';

class SDKErrorHandler {
  SDKErrorHandler({required MeetingPlaceCoreSDKLogger logger})
      : _logger = logger;

  final MeetingPlaceCoreSDKLogger _logger;

  Future<T> handleError<T>(Future<T> Function() operation) async {
    final methodName = 'handleError';

    try {
      return await operation();
    } on SDKException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.message,
          code: e.code.value,
          innerException: e.innerException ?? e,
        ),
        stackTrace,
      );
    } on ControlPlaneSDKException catch (e, stackTrace) {
      _logger.error(
        'Failed to execute ControlPlane SDK operation:',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.message,
          code: e.code,
          innerException: e.innerException,
        ),
        stackTrace,
      );
    } on MeetingPlaceMediatorSDKException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: 'Failure on MeetingPlaceCore SDK operation',
          code: e.code,
          innerException: e.innerException,
        ),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCoreSDKException(
          message: e.toString(),
          code: 'generic',
          innerException: e,
        ),
        stackTrace,
      );
    }
  }
}
