import 'channel_repository.dart';
import 'connection_offer_repository.dart';
import 'group_repository.dart';
import 'group_not_implemented_repository.dart';
import 'key_repository.dart';
import 'identity_repository.dart';
import 'identity_repository_in_memory.dart';

class RepositoryConfig {
  RepositoryConfig({
    required this.connectionOfferRepository,
    required this.channelRepository,
    required this.keyRepository,
    IdentityRepository? identityRepository,
    this.groupRepository = const GroupNotImplementedRepository(),
  }) : identityRepository = identityRepository ?? InMemoryIdentityRepository();
  final ConnectionOfferRepository connectionOfferRepository;
  final ChannelRepository channelRepository;
  final KeyRepository keyRepository;
  final GroupRepository groupRepository;
  final IdentityRepository identityRepository;
}
