import '../../core/exception/control_plane_exception.dart';

/// GroupAddMemberExceptionCodes enum definitions.
enum GroupAddMemberExceptionCodes {
  generic('discovery_group_add_member_generic');

  const GroupAddMemberExceptionCodes(this.code);
  final String code;
}

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
      code: GroupAddMemberExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final GroupAddMemberExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
