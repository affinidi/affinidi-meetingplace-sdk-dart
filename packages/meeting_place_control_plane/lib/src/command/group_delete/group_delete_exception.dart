import '../../core/exception/control_plane_exception.dart';

/// GroupDeleteExceptionCodes enum definitions.
enum GroupDeleteExceptionCodes {
  generic('discovery_group_delete_generic');

  const GroupDeleteExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Group Delete command/operation.
class GroupDeleteException implements ControlPlaneException {
  GroupDeleteException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [GroupDeleteException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory GroupDeleteException.generic({Object? innerException}) {
    return GroupDeleteException._(
      message: 'Group delete exception: ${innerException.toString()}.',
      code: GroupDeleteExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final GroupDeleteExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
