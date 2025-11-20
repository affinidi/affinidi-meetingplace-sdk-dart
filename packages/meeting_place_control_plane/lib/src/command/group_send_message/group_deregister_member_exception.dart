import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to GroupSendMessage command/operation.
class GroupSendMessageException implements ControlPlaneException {
  GroupSendMessageException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupSendMessageException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupSendMessageException.generic({Object? innerException}) {
    return GroupSendMessageException._(
      message: 'Group send message exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.groupSendMessageGeneric,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
