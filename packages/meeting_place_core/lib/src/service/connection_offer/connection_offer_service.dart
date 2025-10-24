import '../../entity/connection_offer.dart';
import '../../repository/repository.dart';
import 'connection_offer_exception.dart';

class ConnectionOfferService {
  ConnectionOfferService({
    required ConnectionOfferRepository connectionOfferRepository,
    required ChannelRepository channelRepository,
  })  : _connectionOfferRepository = connectionOfferRepository,
        _channelRepository = channelRepository;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelRepository _channelRepository;

  Future<void> ensureConnectionOfferIsClaimable(String offerLink) async {
    final connectionOffer = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(offerLink);

    if (connectionOffer != null && connectionOffer.isPublished()) {
      throw ConnectionOfferException.ownedByClaimingPartyError();
    }

    if (connectionOffer != null && !connectionOffer.isDeleted()) {
      throw ConnectionOfferException.alreadyClaimedByClaimingPartyError();
    }

    final channel = await _channelRepository.findChannelByOfferLink(offerLink);
    if (channel != null) {
      throw ConnectionOfferException.alreadyClaimedByClaimingPartyError();
    }
  }

  Future<ConnectionOffer> markAsDeleted(ConnectionOffer connectionOffer) async {
    await _connectionOfferRepository.updateConnectionOffer(
      connectionOffer.markAsDeleted(),
    );
    return connectionOffer;
  }
}
