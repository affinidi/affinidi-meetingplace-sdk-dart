import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../loggers/mpx_sdk_logger.dart';
import '../repository/channel_repository.dart';
import '../repository/connection_offer_repository.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/connection_offer/connection_offer_exception.dart';
import '../service/mediator/mediator_service.dart';

abstract class BaseEventHandler {
  BaseEventHandler({
    required this.wallet,
    required this.mediatorService,
    required this.connectionOfferRepository,
    required this.channelRepository,
    required this.connectionManager,
    required this.logger,
  });

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

  @internal
  Future<ConnectionOffer> findConnectionByDid(String did) async {
    return await connectionOfferRepository
            .getConnectionOfferByPermanentChannelDid(did) ??
        (throw ConnectionOfferException.offerNotFoundError());
  }

  @internal
  Future<ConnectionOffer> findConnectionByOfferLink(String offerLink) async {
    return await connectionOfferRepository
            .getConnectionOfferByOfferLink(offerLink) ??
        (throw ConnectionOfferException.offerNotFoundError());
  }

  @internal
  Future<Channel> findChannelByDid(String did) async {
    return await channelRepository.findChannelByDid(did) ??
        (throw Exception('Channel not found'));
  }

  @internal
  Future<Channel> findChannelByOfferLink(String offerLink) async {
    return await channelRepository.findChannelByOfferLink(offerLink) ??
        (throw Exception('Channel not found'));
  }

  @internal
  Future<DidManager> findDidManager(Channel channel) {
    final did = channel.permanentChannelDid ??
        (throw ArgumentError('Channel must have a permanent DID'));

    return connectionManager.getDidManagerForDid(wallet, did);
  }
}
