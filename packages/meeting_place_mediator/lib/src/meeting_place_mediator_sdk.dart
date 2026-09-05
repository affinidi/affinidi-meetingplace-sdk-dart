import 'dart:async';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_mediator.dart';
import 'command/get_oob/get_oob.dart';
import 'command/get_oob/get_oob_handler.dart';
import 'command/get_oob/get_oob_output.dart';
import 'command/oob_message/oob_invitation_message.dart';
import 'command/oob_message/oob_invitation_message_handler.dart';
import 'command/oob_message/oob_invitation_message_output.dart';
import 'constants/sdk_constants.dart';
import 'core/command/command.dart';
import 'core/command/command_dispatcher.dart';
import 'core/exception/sdk_exception_mapper.dart';
import 'core/mediator/fetch_message_result.dart';
import 'core/mediator/mediator_exception.dart' show MediatorException;
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
              className: className,
              sdkName: sdkName,
            ) {
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
  /// accept a mediator DID parameter. When a method supports specifying a
  /// mediator DID but none is explicitly provided, this default value will be
  /// used instead.
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
    bool forceNewSession = false,
  }) {
    return _withSdkExceptionHandling(
      () => _mediatorService.authenticateWithDid(
        didManager: didManager,
        mediatorDid: mediatorDid ?? _mediatorDid,
        forceNewSession: forceNewSession,
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
  ///   - [AccessListSet]: Replaces the entire ACL with the provided permissions
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

  /// Allows a client to create an Out-Of-Band invitation in the mediator,
  /// resulting not only in an OOB ID but also returning a URI containing the
  /// OOB ID for ease of sharing and connection establishment.
  ///
  /// - [oobDidManager]: Responsible for managing out-of-band (OOB) DID
  ///   exchanges.
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
  /// - [oobUrl]: Carries an out-of-band invitation used to initiate DIDComm
  ///   interactions outside the normal communication channel, often shared via
  ///   QR code.
  ///
  /// Returns the OOB invitation message details if found, or null if no OOB
  /// invitation is associated with the provided URL.
  ///
  /// Throws a [MediatorException] if there is an error during retrieval.
  Future<OobInvitationMessage?> findOob(Uri oobUrl) {
    return _withSdkExceptionHandling(() async {
      final output = await _execute(GetOobCommand(oobUrl: oobUrl));
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

  /// Encrypts and signs the message using the sender's DID, then sends it to
  /// [MediatorMessageRequest.recipientDidDocument] via DIDComm.
  Future<void> sendMessage(MediatorMessageRequest request) {
    return _withSdkExceptionHandling(
      () => _mediatorService.sendMessage(
        request.message,
        senderDidManager: request.senderDidManager,
        recipientDidDocument: request.recipientDidDocument,
        mediatorDid: request.mediatorDid ?? _mediatorDid,
        next: request.next ?? request.recipientDidDocument.id,
        ephemeral: request.ephemeral ?? false,
        forwardExpiryInSeconds: request.forwardExpiryInSeconds,
      ),
    );
  }

  /// Stores incoming DIDComm messages to manage the sending process
  /// efficiently, ensuring messages are properly handled and dispatched.
  Future<void> queueMessage(MediatorMessageRequest request) {
    return _withSdkExceptionHandling(
      () => _mediatorService.queueMessage(
        request.message,
        senderDidManager: request.senderDidManager,
        recipientDidDocument: request.recipientDidDocument,
        mediatorDid: request.mediatorDid ?? _mediatorDid,
        next: request.next ?? request.recipientDidDocument.id,
        ephemeral: request.ephemeral,
        forwardExpiryInSeconds: request.forwardExpiryInSeconds,
      ),
    );
  }

  /// Fetches messages from the mediator.
  Future<List<FetchMessageResult>> fetchMessages(
    FetchMessagesRequest request,
  ) async {
    return _withSdkExceptionHandling(() async {
      final results = await _mediatorService.fetch(
        didManager: request.didManager,
        mediatorDid: request.mediatorDid ?? _mediatorDid,
        deleteOnRetrieve: request.deleteOnRetrieve,
        startFrom: request.startFrom,
        fetchMessagesBatchSize: request.fetchMessagesBatchSize,
        expectedMessageWrappingTypes: request.expectedMessageWrappingTypes ??
            _options.expectedMessageWrappingTypes,
      );

      if (request.deleteFailedMessages) {
        final messageHashes = results
            .where((m) => m.error != null)
            .map((m) => m.messageHash)
            .toList();

        await _mediatorService.delete(
          didManager: request.didManager,
          mediatorDid: request.mediatorDid ?? _mediatorDid,
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

  /// Deletes stored messages from the mediator's queue, removing them
  /// permanently after they have been retrieved or are no longer needed.
  ///
  /// - [didManager]: The [DidManager] instance used for authentication with
  ///   the mediator and contains the identity credentials needed for the
  ///   session.
  /// - [messageHashes]: List of cryptographic hashes representing stored
  ///   messages, used to verify and track messages without exposing their
  ///   content.
  /// - [mediatorDid]: Optional mediator DID to authenticate against.
  /// If not provided, the SDK instance’s default mediator DID will be used.
  Future<void> deleteMessages({
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
  Future<String?> findMediatorDidFromUrl(String mediatorEndpoint) {
    return _withSdkExceptionHandling(
      () => _mediatorResolver.findMediatorDidFromUrl(mediatorEndpoint),
    );
  }

  /// Releases resources held by this SDK instance, closing the underlying
  /// HTTP client.
  Future<void> dispose() async {
    _mediatorResolver.dispose();
  }

  Future<T> _execute<T>(MediatorCommand<T> command) async {
    return await _dispatcher.dispatch(command);
  }

  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(toMediatorSdkException(e), stackTrace);
    }
  }
}
