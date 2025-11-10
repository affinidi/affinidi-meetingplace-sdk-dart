import '../entity/channel.dart';

abstract interface class ChannelRepository {
  Future<void> createChannel(Channel channel);
  Future<void> updateChannel(Channel channel);
  Future<void> deleteChannel(Channel channel);

  Future<Channel?> findChannelByDid(String did);
  Future<Channel?> findChannelByOtherPartyPermanentChannelDid(String did);
}
