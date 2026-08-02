enum VtaErrorType {
  transport,
  auth,
  acl,
  parse,
  proof,
  cache,
  protocol,
  validation,
}

class VtaException implements Exception {
  const VtaException({
    required this.message,
    required this.type,
    this.code,
    this.statusCode,
    this.body,
    this.originalMessage,
  });

  final String message;
  final VtaErrorType type;
  final String? code;
  final int? statusCode;
  final String? body;
  final String? originalMessage;

  @override
  String toString() {
    final parts = <String>['type=${type.name}', 'message=$message'];
    if (code != null && code!.isNotEmpty) {
      parts.add('code=$code');
    }
    if (statusCode != null) {
      parts.add('statusCode=$statusCode');
    }
    if (body != null && body!.isNotEmpty) {
      parts.add('body=$body');
    }
    if (originalMessage != null && originalMessage!.isNotEmpty) {
      parts.add('originalMessage=$originalMessage');
    }
    return 'VtaException(${parts.join(', ')})';
  }
}

class VtaClientException extends VtaException {
  const VtaClientException(
    String message, {
    super.statusCode,
    super.body,
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.protocol,
       );
}

class VtaTransportException extends VtaException {
  const VtaTransportException(
    String message, {
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.transport,
       );
}

class VtaAuthException extends VtaException {
  const VtaAuthException(
    String message, {
    super.statusCode,
    super.body,
    super.code,
  }) : super(
         message: message,
         type: VtaErrorType.auth,
       );
}

class VtaAclException extends VtaException {
  const VtaAclException(
    String message, {
    super.statusCode,
    super.body,
    super.code,
  }) : super(
         message: message,
         type: VtaErrorType.acl,
       );
}

class VtaParseException extends VtaException {
  const VtaParseException(
    String message, {
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.parse,
       );
}

class VtaProofException extends VtaException {
  const VtaProofException(
    String message, {
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.proof,
       );
}

class VtaCacheException extends VtaException {
  const VtaCacheException(
    String message, {
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.cache,
       );
}

class VtaProtocolException extends VtaException {
  const VtaProtocolException(
    String message, {
    super.statusCode,
    super.body,
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.protocol,
       );
}

class VtaValidationException extends VtaException {
  const VtaValidationException(
    String message, {
    super.code,
    super.originalMessage,
  }) : super(
         message: message,
         type: VtaErrorType.validation,
       );
}
