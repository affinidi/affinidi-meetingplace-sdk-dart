import '../entity/channel.dart';

/// Persists and retrieves [Channel] entities.
///
/// Implementations back the SDK's channel state with durable storage (for
/// example a Drift/SQLite database) so channels survive across app restarts.
abstract interface class ChannelRepository {
  /// Persists a new [channel], including its contact cards.
  Future<void> createChannel(Channel channel);

  /// Replaces the stored channel matching [channel]'s id with [channel].
  ///
  /// Implementations are expected to throw if no channel with that id
  /// exists yet.
  Future<void> updateChannel(Channel channel);

  /// Deletes the stored channel matching [channel]'s id, if any.
  Future<void> deleteChannel(Channel channel);

  /// Finds a channel by its own or the other party's permanent channel DID.
  ///
  /// Returns `null` if no matching channel exists.
  Future<Channel?> findChannelByDid(String did);

  /// Finds a channel by the other party's permanent channel DID.
  ///
  /// Returns `null` if no matching channel exists.
  Future<Channel?> findChannelByOtherPartyPermanentChannelDid(String did);
}
