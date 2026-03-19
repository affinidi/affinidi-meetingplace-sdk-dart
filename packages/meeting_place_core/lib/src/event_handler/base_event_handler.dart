import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_service.dart';
import '../utils/string.dart';
import 'exceptions/empty_message_list_exception.dart';
import 'exceptions/event_handler_exception.dart';

abstract class BaseEventHandler<T> {
  BaseEventHandler({
    required this.wallet,
    required this.mediatorService,
    required this.connectionOfferRepository,
    required this.channelService,
    required this.connectionManager,
    required this.logger,
    ControlPlaneEventHandlerManagerOptions options =
        const ControlPlaneEventHandlerManagerOptions(),
  }) : _options = options;

  @internal
  final Wallet wallet;

  @internal
  final MediatorService mediatorService;

  @internal
  final ConnectionOfferRepository connectionOfferRepository;

  @internal
  final ChannelService channelService;

  @internal
  final ConnectionManager connectionManager;

  @internal
  final MeetingPlaceCoreSDKLogger logger;

  final ControlPlaneEventHandlerManagerOptions _options;

  @internal
  ControlPlaneEventHandlerManagerOptions get options => _options;

  @internal
  Future<ConnectionOffer> findConnectionByDid(String did) async {
    return await connectionOfferRepository
            .getConnectionOfferByPermanentChannelDid(did) ??
        (throw EventHandlerException.offerNotFound());
  }

  @internal
  Future<ConnectionOffer> findConnectionByOfferLink(String offerLink) async {
    return await connectionOfferRepository.getConnectionOfferByOfferLink(
          offerLink,
        ) ??
        (throw EventHandlerException.offerNotFound());
  }

  @internal
  Future<DidManager> findDidManager(Channel channel) {
    final did =
        channel.permanentChannelDid ??
        (throw EventHandlerException.missingPermanentChannelDid(
          channelId: channel.id,
        ));

    return connectionManager.getDidManagerForDid(wallet, did);
  }

  @internal
  Future<List<MediatorMessage>> fetchMessagesFromMediatorWithRetry({
    required DidManager didManager,
    required String mediatorDid,
    required FetchMessagesOptions options,
  }) {
    return retry(
      () async {
        final messages = await mediatorService.fetchMessages(
          didManager: didManager,
          mediatorDid: mediatorDid,
          options: options,
        );

        if (messages.isEmpty) {
          logger.warning(
            'No messages found for ${options.filterByMessageTypes.join(',')}',
            name: 'fetchMessagesFromMediatorWithRetry',
          );
          throw EmptyMessageListException();
        }

        return messages;
      },
      retryIf: (e) => e is EmptyMessageListException,
      onRetry: (e) {
        logger.info(
          'Retry fetching ${options.filterByMessageTypes.join(',')} messages',
          name: 'fetchMessagesFromMediatorWithRetry',
        );
      },
      maxAttempts: _options.maxRetries,
      maxDelay: _options.maxRetriesDelay,
    );
  }

  /// Each event handler will implement how to process the message based on its
  /// type and return the associated channels.
  ///
  /// Parameters:
  /// - [message]: The message to process, which is expected to be of a specific
  ///   type based on the event handler.
  /// - [connection]: Optional parameter that can be used by event handlers that
  ///   require connection details to process the message.
  /// - [channel]: Optional parameter that can be used by event handlers
  ///   that require channel details to process the message.
  ///
  /// Returns a [Future] that resolves to a list of [Channel] objects associated
  /// with the processed message. The implementation of this method will depend
  /// on the specific event handler and the type of message being processed.
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required T event,
    ConnectionOffer? connection,
    Channel? channel,
  });

  /// Helper method to process events that follow the pattern of fetching
  /// messages from the mediator, processing each message, and then deleting the
  /// messages from the mediator after processing. This method can be used by
  /// multiple event handlers to avoid code duplication and ensure consistent
  /// processing of messages across different event types.
  ///
  /// Parameters:
  /// - [didManager]: The [DidManager] instance to use for fetching and deleting messages from the mediator.
  /// - [mediatorDid]: The DID of the mediator to fetch messages from.
  /// - [messageType]: The type of messages to fetch from the mediator, which should correspond to the specific event being processed.
  /// - [connection]: Optional parameter that can be used by event handlers that require connection details to process the message.
  /// - [channel]: Optional parameter that can be used by event handlers that require channel details to process the message.
  ///
  /// Returns a [Future] that resolves to a list of [Channel] objects
  /// associated with the processed messages. The method will fetch messages of
  /// the specified type from the mediator, process each message using the
  /// [processMessage] method, and then delete the messages from the mediator
  /// after processing.
  ///
  /// If no messages are found, it will throw an [EmptyMessageListException]
  /// and log a warning. If any other error occurs during processing, it will
  /// log the error and rethrow the exception.
  ///
  /// Returns list of channels associated with the processed messages.
  ///
  /// Throws [EmptyMessageListException] if no messages are found to process.
  /// Rethrows any exceptions that occur during processing after logging the
  /// error.
  Future<List<Channel>> processEvent({
    required dynamic event,
    required DidManager didManager,
    required String mediatorDid,
    required FetchMessagesOptions fetchMessageOptions,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    final channels = <Channel>[];
    final didDocument = await didManager.getDidDocument();

    final filterByMessageTypes = fetchMessageOptions.filterByMessageTypes.join(
      ',',
    );

    // Use try-catch-finally to ensure deletion always happens

    try {
      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: didManager,
        mediatorDid: mediatorDid,
        options: fetchMessageOptions,
      );

      logger.info(
        '''Found ${messages.length} messages for type
        $filterByMessageTypes and DID ${didDocument.id.topAndTail()}''',
        name: 'processEvent',
      );

      for (final result in messages) {
        bool success = false;
        Object? error;
        StackTrace? stackTrace;
        Channel? channelResult;
        try {
          channelResult = await processMessage(
            result.plainTextMessage,
            event: event,
            connection: connection,
            channel: channel,
          );
          success = true;
        } catch (e, st) {
          error = e;
          stackTrace = st;
        } finally {
          await mediatorService.deleteMessages(
            didManager: didManager,
            mediatorDid: mediatorDid,
            messageHashes: [result.messageHash!],
          );
          if (success) {
            logger.info(
              '''Completed processing message types $filterByMessageTypes and DID ${didDocument.id.topAndTail()}''',
              name: 'processEvent',
            );
            channels.add(channelResult!);
          } else {
            logger.error(
              '''Failed to process message for DID ${didDocument.id.topAndTail()} and message type $filterByMessageTypes. Message deleted.''',
              error: error,
              stackTrace: stackTrace,
              name: 'processEvent',
            );
          }
        }
      }

      return channels;
    } on EmptyMessageListException {
      logger.warning(
        '''No messages found to process for types $filterByMessageTypes and DID
        ${didDocument.id.topAndTail()}''',
        name: 'processEvent',
      );

      return [];
    } catch (e, stackTrace) {
      logger.error(
        '''Failed to process event for DID ${didDocument.id.topAndTail()}
        and message type $filterByMessageTypes''',
        error: e,
        stackTrace: stackTrace,
        name: 'processEvent',
      );
      rethrow;
    }
  }
}
