import 'dart:async';

import '../meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';
import 'package:didcomm/didcomm.dart';
import 'command/get_oob/get_oob.dart';
import 'command/get_oob/get_oob_handler.dart';
import 'command/get_oob/get_oob_output.dart';
import 'command/oob_message/oob_invitation_message.dart';
import 'command/oob_message/oob_invitation_message_handler.dart';
import 'command/oob_message/oob_invitation_message_output.dart';
import 'constants/sdk_constants.dart';
import 'core/command/command.dart';
import 'core/command/command_dispatcher.dart';
import 'core/exception/i_mediator_exception.dart';
import 'core/mediator/fetch_message_result.dart';
import 'core/mediator/mediator_resolver.dart';
import 'core/mediator/mediator_service.dart';
import 'protocol/message/oob_invitation_message.dart';

class MeetingPlaceMediatorSDK {
  MeetingPlaceMediatorSDK({
    required String mediatorDid,
    required DidResolver didResolver,
    MeetingPlaceMediatorSDKOptions options =
        const MeetingPlaceMediatorSDKOptions(),
    MediatorResolver? mediatorResolver,
    MeetingPlaceMediatorSDKLogger? logger,
  })  : _mediatorDid = mediatorDid,
        _options = options,
        _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
                className: className, sdkName: sdkName) {
    _mediatorService = MediatorService(
      didResolver: didResolver,
      options: _options,
      logger: _logger,
    );

    _mediatorResolver = mediatorResolver ?? MediatorResolver(logger: _logger);

    _dispatcher = CommandDispatcher();
    _dispatcher.registerHandler<OobInvitationMessageCommand,
        OobInvitationMessageOutput>(
      OobInvitationMessageHandler(
        mediatorService: _mediatorService,
        didResolver: didResolver,
      ),
    );
    _dispatcher.registerHandler<GetOobCommand, GetOobOutput>(
      GetOobHandler(mediatorService: _mediatorService),
    );
  }
  static const String className = 'MeetingPlaceMediatorSDK';

  late final MediatorResolver _mediatorResolver;
  late final MediatorService _mediatorService;
  late final CommandDispatcher _dispatcher;
  final MeetingPlaceMediatorSDKOptions _options;
  final MeetingPlaceMediatorSDKLogger _logger;

  String _mediatorDid;

  /// Updates the default mediator DID for this mediator SDK instance.
  ///
  /// The default mediator DID serves as a fallback value for method calls that
  /// accept a mediator DID parameter. When a method supports specifying a mediator
  /// DID but none is explicitly provided, this default value will be used instead.
  ///
  /// - [mediatorDid]: The new default mediator DID to set for this instance.
  ///   Must be a valid DID format.
  set mediatorDid(String mediatorDid) {
    _mediatorDid = mediatorDid;
  }

  /// Authenticates to a mediator instance using the provided DID manager.
  ///
  /// This method establishes an authenticated session with the mediator.
  /// If a valid session already exists in the internal cache for the same DID
  /// manager and mediator combination, the cached session client will be
  /// returned instead of creating a new one.
  ///
  /// - [didManager]: The DidManager instance used for authentication with the
  ///   mediator. This contains the identity credentials needed for the session.
  /// - [mediatorDid]: Optional mediator DID to authenticate against. If not
  ///   provided, the SDK instance's default mediator DID will be used.
  ///
  /// Returns a session client that holds authentication details for mediator
  /// interactions.
  Future<MediatorClient> authenticateWithDid(
    DidManager didManager, {
    String? mediatorDid,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.authenticateWithDid(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
      ),
    );
  }

  /// Updates the Access Control List (ACL) for a specific owner on the
  /// mediator instance.
  ///
  /// This method modifies the ACL permissions for the specified owner's DID
  /// by sending the provided ACL payload to the mediator. The ACL determines
  /// which entities have access to the owner's resources and what operations
  /// they can perform.
  ///
  /// - [ownerDidManager]: The DidManager instance representing the owner whose
  ///   ACL should be updated.
  ///
  /// - [acl]: The ACL payload containing the permission changes to apply.
  ///   Supported action types include:
  ///   - [AccessListAdd]: Grants new permissions to specified entities
  ///   - [AccessListRemove]: Revokes existing permissions from specified
  ///       entities
  ///   - [AclSet]: Replaces the entire ACL with the provided permissions
  /// - [mediatorDid]: Optional mediator DID to authenticate against. If not
  ///   provided, the SDK instance's default mediator DID will be used.
  Future<void> updateAcl({
    required DidManager ownerDidManager,
    required AclBody acl,
    String? mediatorDid,
  }) async {
    return _withSdkExceptionHandling(() {
      return _mediatorService.updateAcl(
        ownerDidManager: ownerDidManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        acl: acl,
      );
    });
  }

  /// Allows a client to create an Out-Of-Band invitation in the mediator, resulting not only in an OOB ID
  /// but also returning a URI containing the OOB ID for ease of sharing and connection establishment.
  ///
  /// - [oobDidManager]: Responsible for managing out-of-band (OOB) DID exchanges.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  Future<Uri> createOob(DidManager oobDidManager, String? mediatorDid) {
    return _withSdkExceptionHandling(() async {
      final output = await _execute(
        OobInvitationMessageCommand(
          oobDidManager: oobDidManager,
          mediatorDid: mediatorDid ?? _mediatorDid,
        ),
      );
      return output.oobUrl;
    });
  }

  /// Allows a client to retrieve the OOB details from the mediator.
  ///
  /// - [didManager]: The DidManager instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  /// - [oobUrl]: Carries an out-of-band invitation used to initiate DIDComm interactions
  /// outside the normal communication channel, often shared via QR code.
  Future<OobInvitationMessage> getOob(
    Uri oobUrl, {
    required DidManager didManager,
  }) {
    return _withSdkExceptionHandling(() async {
      final output = await _execute(
        GetOobCommand(oobUrl: oobUrl, didManager: didManager),
      );
      return output.oobInvitationMessage;
    });
  }

  /// Subscribes to incoming messages from the mediator.
  ///
  /// - [didManager]: DID manager for mediator authentication.
  ///   Uses this manager's DID document to establish a mediator session.
  ///
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  ///   If not provided, the SDK instance’s default mediator DID will be used.
  ///
  /// Returns [MediatorStreamSubscription]
  Future<MediatorStreamSubscription> subscribeToMessages(
    DidManager didManager, {
    MediatorStreamSubscriptionOptions options =
        const MediatorStreamSubscriptionOptions(),
    String? mediatorDid,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.createStreamSubscription(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        deleteMessageDelay: options.deleteMessageDelay,
        messageWrappingTypes: options.expectedMessageWrappingTypes,
        fetchMessagesOnConnect: options.fetchMessagesOnConnect,
      ),
    );
  }

  /// Encrypts and signs the message using the sender’ s DID, then sends it to [recipientDidDocument] via DIDComm.
  ///
  /// - [recipientDidDocument]: DID document that contains the recipient agent’s public keys,
  /// service endpoints, and routing information required to securely receive, decrypt,
  /// and respond to DIDComm messages.
  /// - [senderDidManager]: The DidManager instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
    String? mediatorDid,
    String? next,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.sendMessage(
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
        mediatorDid: mediatorDid ?? _mediatorDid,
        next: next ?? recipientDidDocument.id,
        ephemeral: ephemeral ?? false,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      ),
    );
  }

  /// Stores incoming DIDComm messages to manage the sending process efficiently,
  /// ensuring messages are properly handled and dispatched.
  ///
  /// - [recipientDidDocument]:  DID document that contains the recipient agent’s public keys,
  /// service endpoints, and routing information required to securely receive, decrypt,
  /// and respond to DIDComm messages.
  /// - [senderDidManager]: The DidManager instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  Future<void> queueMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
    String? mediatorDid,
    String? next,
    bool? ephemeral,
    int? forwardExpiryInSeconds,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.queueMessage(
        message,
        senderDidManager: senderDidManager,
        recipientDidDocument: recipientDidDocument,
        mediatorDid: mediatorDid ?? _mediatorDid,
        next: next ?? recipientDidDocument.id,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      ),
    );
  }

  /// Fetches messages from the mediator.
  ///
  /// - [didManager]: The DidManager instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  /// - [deleteOnRetrieve]: Boolean flag indicating whether messages should be deleted upon retrieval.
  Future<List<FetchMessageResult>> fetchMessages({
    required DidManager didManager,
    String? mediatorDid,
    DateTime? startFrom,
    int? fetchMessagesBatchSize,
    bool deleteOnRetrieve = false,
    bool deleteFailedMessages = false,
    List<MessageWrappingType>? expectedMessageWrappingTypes,
  }) async {
    return _withSdkExceptionHandling(() async {
      final results = await _mediatorService.fetch(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        deleteOnRetrieve: deleteOnRetrieve,
        startFrom: startFrom,
        fetchMessagesBatchSize: fetchMessagesBatchSize,
        expectedMessageWrappingTypes: expectedMessageWrappingTypes ??
            _options.expectedMessageWrappingTypes,
      );

      if (deleteFailedMessages) {
        final messageHashes = results
            .where((m) => m.error != null)
            .map((m) => m.messageHash)
            .toList();

        await _mediatorService.delete(
          didManager: didManager,
          mediatorDid: mediatorDid ?? _mediatorDid,
          messageHashes: messageHashes,
        );
      }

      return results
          .where((r) => r.message is PlainTextMessage && r.error == null)
          .map(
            (r) => FetchMessageResult(
              messageHash: r.messageHash,
              message: r.message,
            ),
          )
          .toList();
    });
  }

  /// Deletes stored messages from the mediator’s queue,
  /// removing them permanently after they have been retrieved or are no longer needed.
  ///
  /// - [didManager]: The DidManager instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  /// - [messageHashes]: List of cryptographic hashes representing stored messages,
  /// used to verify and track messages without exposing their content.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  Future<void> deletedMessages({
    required DidManager didManager,
    required List<String> messageHashes,
    String? mediatorDid,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.delete(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        messageHashes: messageHashes,
      ),
    );
  }

  /// Fetches the Mediator DID from a mediator's endpoint.
  ///
  /// This method performs a GET request to `/.well-known/did` at the given
  /// [mediatorEndpoint] and returns the `mediatorDid` string if found.
  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) {
    return _withSdkExceptionHandling(
      () => _mediatorResolver.getMediatorDidFromUrl(mediatorEndpoint),
    );
  }

  Future<T> _execute<T>(MediatorCommand<T> command) async {
    return await _dispatcher.dispatch(command);
  }

  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on IMediatorException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceMediatorSDKException(
          message: 'Meeting Place Mediator SDK exception',
          code: e.code.value,
          innerException: e.innerException ?? e,
        ),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceMediatorSDKException(
          message: 'Failure on Mediator SDK exception',
          code: MediatorSdkExceptionErrorCodes.generic.name,
          innerException: e,
        ),
        stackTrace,
      );
    }
  }
}
