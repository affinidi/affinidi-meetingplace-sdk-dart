import 'channel_repository.dart';
import 'connection_offer_repository.dart';
import 'group_not_implemented_repository.dart';
import 'group_repository.dart';
import 'key_repository.dart';

/// Bundles the repository implementations the SDK uses for persistence.
class RepositoryConfig {
  /// Creates a [RepositoryConfig] from the given repository implementations.
  ///
  /// [groupRepository] defaults to [GroupNotImplementedRepository] when
  /// group support isn't needed.
  RepositoryConfig({
    required this.connectionOfferRepository,
    required this.channelRepository,
    required this.keyRepository,
    this.groupRepository = const GroupNotImplementedRepository(),
  });

  /// Persists and retrieves connection offers.
  final ConnectionOfferRepository connectionOfferRepository;

  /// Persists and retrieves channels.
  final ChannelRepository channelRepository;

  /// Persists and retrieves key/DID associations.
  final KeyRepository keyRepository;

  /// Persists and retrieves groups.
  final GroupRepository groupRepository;
}
