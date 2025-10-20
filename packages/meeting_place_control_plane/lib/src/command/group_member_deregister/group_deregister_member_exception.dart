import '../../core/exception/control_plane_exception.dart';

/// GroupDeregisterExceptionCodes enum definitions.
enum GroupDeregisterExceptionCodes {
  generic('discovery_group_deregister_member_generic');

  const GroupDeregisterExceptionCodes(this.code);
  final String code;
}

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
      code: GroupDeregisterExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final GroupDeregisterExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
