import 'dart:convert';

import '../../meeting_place_mediator_sdk_error_code.dart';
import '../acl/acl_body.dart';
import '../exception/i_mediator_exception.dart';

/// Encapsulates an error message, a specific error code from
/// [MeetingPlaceMediatorSDKErrorCode], and the original exception object that
/// caused this error.
///
/// **Parameters:**
/// - [message]: A descriptive text explaining the nature of the exception or
///   error.
/// - [code]: An enumeration value representing the type or category of the
///   exception for easier classification.
/// - [innerException]: Holds the original exception or error object.
class MediatorException implements IMediatorException {
  MediatorException({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates an exception related to errors encountered while updating ACL.
  ///
  /// **Parameters:**
  /// - [acl]: The ACL payload containing the permission changes to apply.
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.updateAclError({
    required AclBody acl,
    Object? innerException,
  }) {
    return MediatorException(
      message:
          '''Mediator Error: Failed to update ACL with body ${jsonEncode(acl.toJson())}.''',
      code: MeetingPlaceMediatorSDKErrorCode.updateAclError,
      innerException: innerException,
    );
  }

  /// Represents an error when subscription to a websocket channel or stream
  /// fails.
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.subscribeToWebsocketError({
    Object? innerException,
  }) {
    return MediatorException(
      message: 'Mediator Error: Failed to subscribe to websocket.',
      code: MeetingPlaceMediatorSDKErrorCode.subscribeToWebsocketError,
      innerException: innerException,
    );
  }

  /// Indicates failure or error during the process of sending a message
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.sendMessageError({Object? innerException}) {
    return MediatorException(
      message: 'Mediator Error: Failed to send message to mediator.',
      code: MeetingPlaceMediatorSDKErrorCode.sendMessageError,
      innerException: innerException,
    );
  }

  /// Denotes an error that occurs while queuing a message for delivery or
  /// processing.
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.queueMessageError({Object? innerException}) {
    return MediatorException(
      message: 'Mediator Error: Failed to queue message.',
      code: MeetingPlaceMediatorSDKErrorCode.queueMessageError,
      innerException: innerException,
    );
  }

  /// Represents problems related to user authentication failures.
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.authenticationError({Object? innerException}) {
    return MediatorException(
      message: 'Mediator Error: Authentication failed.',
      code: MeetingPlaceMediatorSDKErrorCode.authenticationError,
      innerException: innerException,
    );
  }

  /// Creates an exception when deleting a message is unsuccessful.
  ///
  /// **Parameters:**
  /// - [errors]: List of strings that contains the error messages encountered
  /// during the deletion of messages.
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.deleteMessagesError({
    required List<String> errors,
    Object? innerException,
  }) {
    return MediatorException(
      message:
          '''Mediator Error: Failed to delete at least one message: ${errors.join(',')}''',
      code: MeetingPlaceMediatorSDKErrorCode.deleteMessagesError,
      innerException: innerException,
    );
  }

  /// Indicates failure in retrieving mediator DID.
  ///
  /// **Parameters:**
  /// - [mediatorEndpoint]: The base URL of the mediator service.
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.getMediatorDidError({
    required String mediatorEndpoint,
    Object? innerException,
  }) {
    return MediatorException(
      message:
          'Mediator Error: Failed to fetch DID from $mediatorEndpoint/.well-known/did.',
      code: MeetingPlaceMediatorSDKErrorCode.getMediatorDidError,
      innerException: innerException,
    );
  }

  /// Represents errors related to websocket operations.
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.websocketError({Object? innerException}) {
    return MediatorException(
      message: 'Mediator Error: error on websocket connection',
      code: MeetingPlaceMediatorSDKErrorCode.websocketError,
      innerException: innerException,
    );
  }

  /// Indicates failure on finding matching key agreement.
  ///
  /// **Parameters:**
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.keyAgreementMismatch({Object? innerException}) {
    return MediatorException(
      message: 'Mediator Error: key agreement match not found',
      code: MeetingPlaceMediatorSDKErrorCode.keyAgreementMismatch,
      innerException: innerException,
    );
  }

  /// Represents an error that occurs when fetching an OOB invitation fails.
  ///
  /// **Parameters:**
  /// - [oobUrl]: The URL of the OOB invitation that failed to be fetched.
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.oobError({
    required String oobUrl,
    Object? innerException,
  }) {
    return MediatorException(
      message: 'Mediator Error: Failed to fetch OOB invitation from $oobUrl.',
      code: MeetingPlaceMediatorSDKErrorCode.oobError,
      innerException: innerException,
    );
  }

  /// Indicates a network error occurred while fetching the OOB invitation.
  ///
  /// **Parameters:**
  /// - [oobUrl]: The URL of the OOB invitation that failed to be
  ///   fetched due to a network error.
  /// - [innerException]: Holds the original exception or error object.
  factory MediatorException.oobNetworkError({
    required String oobUrl,
    Object? innerException,
  }) {
    return MediatorException(
      message:
          '''Mediator Error: Network error while fetching OOB invitation from
          $oobUrl.''',
      code: MeetingPlaceMediatorSDKErrorCode.networkError,
      innerException: innerException,
    );
  }

  @override
  final String message;

  @override
  final MeetingPlaceMediatorSDKErrorCode code;

  @override
  final Object? innerException;

  @override
  String toString() => '$message (code: $code)';
}
