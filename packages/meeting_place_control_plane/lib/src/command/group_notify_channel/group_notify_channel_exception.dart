import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to Group Notify Channel
/// command/operation.
class GroupNotifyChannelException implements ControlPlaneException {
  GroupNotifyChannelException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupNotifyChannelException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupNotifyChannelException.generic({Object? innerException}) {
    return GroupNotifyChannelException._(
      message: 'Group notify channel exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.groupNotifyChannelGeneric,
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
