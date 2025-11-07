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

    if (connectionOffer != null &&
        !connectionOffer.isDeleted() &&
        !connectionOffer.isFinalised()) {
      throw ConnectionOfferException.alreadyClaimedByClaimingPartyError();
    }

    if (connectionOffer != null) {
      final channel = await _channelRepository.findChannelByDid(
        connectionOffer.permanentChannelDid!,
      );
      if (channel?.isGroup == true && channel?.isInaugurated == true) {
        throw ConnectionOfferException.alreadyClaimedByClaimingPartyError();
      }
    }
  }

  Future<ConnectionOffer> markAsDeleted(ConnectionOffer connectionOffer) async {
    final deletedOffer = connectionOffer.markAsDeleted();
    await _connectionOfferRepository.updateConnectionOffer(deletedOffer);
    return deletedOffer;
  }
}
