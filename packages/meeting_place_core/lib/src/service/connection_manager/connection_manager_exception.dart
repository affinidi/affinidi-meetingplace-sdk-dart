import '../../exception/mpx_exception.dart';
import '../../utils/string.dart';

enum ConnectionManagerExceptionCodes {
  keyPairNotFoundError('connection_manager_key_pair_not_found');

  const ConnectionManagerExceptionCodes(this.code);

  final String code;
}

class ConnectionManagerException implements MpxException {
  ConnectionManagerException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory ConnectionManagerException.keyPairNotFoundError({
    required String did,
    Object? innerException,
  }) {
    return ConnectionManagerException(
      message:
          'Connection manager exception: DidManager could not be created for ${did.topAndTail()}',
      code: ConnectionManagerExceptionCodes.keyPairNotFoundError,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final ConnectionManagerExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
