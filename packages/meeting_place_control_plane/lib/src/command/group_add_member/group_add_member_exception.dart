import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Group Add Member command/operation.
class GroupAddMemberException implements ControlPlaneException {
  GroupAddMemberException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupAddMemberException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupAddMemberException.generic({Object? innerException}) {
    return GroupAddMemberException._(
      message: 'Group add member exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.groupAddMemberGeneric,
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
