import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to GroupDeregisterMember
/// command/operation.
class GroupDeregisterMemberException implements ControlPlaneException {
  GroupDeregisterMemberException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupDeregisterMemberException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupDeregisterMemberException.generic({Object? innerException}) {
    return GroupDeregisterMemberException._(
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
