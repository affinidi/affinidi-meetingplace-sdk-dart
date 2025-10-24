import '../entity/channel.dart';

abstract interface class ChannelRepository {
  Future<void> createChannel(Channel channel);
  Future<void> updateChannel(Channel channel);
  Future<Channel?> findChannelByDid(String did);
  Future<Channel?> findChannelByOtherPartyPermanentChannelDid(String did);
  Future<Channel?> findChannelByOfferLink(String offerLink);
  Future<void> deleteChannel(Channel channel);
}
