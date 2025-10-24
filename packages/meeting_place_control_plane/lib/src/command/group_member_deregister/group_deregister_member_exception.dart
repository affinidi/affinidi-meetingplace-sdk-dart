import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Group Deregistration Member command/operation.
class GroupDeregisterException implements ControlPlaneException {
  GroupDeregisterException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupDeregisterException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupDeregisterException.generic({Object? innerException}) {
    return GroupDeregisterException._(
      message:
          'Group deregister member exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.groupDeregisterMemberGeneric,
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
