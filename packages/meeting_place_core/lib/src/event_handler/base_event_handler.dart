import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../protocol/meeting_place_protocol.dart';
import '../repository/channel_repository.dart';
import '../repository/connection_offer_repository.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/connection_offer/connection_offer_exception.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_message.dart';
import '../service/mediator/mediator_service.dart';
import 'control_plane_event_handler_manager_options.dart';
import 'exceptions/empty_message_list_exception.dart';
import 'exceptions/event_handler_exception.dart';

abstract class BaseEventHandler {
  BaseEventHandler({
    required this.wallet,
    required this.mediatorService,
    required this.connectionOfferRepository,
    required this.channelRepository,
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
  final ChannelRepository channelRepository;

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
        (throw ConnectionOfferException.offerNotFoundError());
  }

  @internal
  Future<ConnectionOffer> findConnectionByOfferLink(String offerLink) async {
    return await connectionOfferRepository.getConnectionOfferByOfferLink(
          offerLink,
        ) ??
        (throw ConnectionOfferException.offerNotFoundError());
  }

  @internal
  Future<Channel> findChannelByDid(String did) async {
    return await channelRepository.findChannelByDid(did) ??
        (throw EventHandlerException.channelNotFound(did: did));
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
    required MeetingPlaceProtocol messageType,
  }) {
    return retry(
      () async {
        final messages = await mediatorService.fetchMessages(
          didManager: didManager,
          mediatorDid: mediatorDid,
          options: FetchMessagesOptions(
            filterByMessageTypes: [messageType.value],
          ),
        );

        if (messages.isEmpty) {
          logger.warning(
            'No messages found for ${messageType.value}',
            name: 'fetchMessagesFromMediatorWithRetry',
          );
          throw EmptyMessageListException();
        }

        return messages;
      },
      retryIf: (e) => e is EmptyMessageListException,
      onRetry: (e) {
        logger.info(
          'Retry fetching ${messageType.value} messages',
          name: 'fetchMessagesFromMediatorWithRetry',
        );
      },
      maxAttempts: _options.maxRetries,
      maxDelay: _options.maxRetriesDelay,
    );
  }

  @internal
  Future<bool> doesChannelExists(String did) async {
    final existingChannel = await channelRepository
        .findChannelByOtherPartyPermanentChannelDid(did);

    return existingChannel != null;
  }

  @internal
  Future<void> deleteMessageFromMediator({
    required DidManager publishedOfferDidManager,
    required String mediatorDid,
    required String messageHash,
  }) {
    return mediatorService.deletedMessages(
      didManager: publishedOfferDidManager,
      mediatorDid: mediatorDid,
      messageHashes: [messageHash],
    );
  }
}
