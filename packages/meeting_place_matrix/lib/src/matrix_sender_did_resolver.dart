import 'package:meeting_place_core/meeting_place_core.dart';

import 'matrix_service.dart';
import 'matrix_user_id_binding.dart';

class MatrixSenderDidResolver {
  MatrixSenderDidResolver({
    required MeetingPlaceCoreSDK coreSDK,
    required MatrixService matrixService,
  }) : _coreSDK = coreSDK,
       _matrixService = matrixService;

  final MeetingPlaceCoreSDK _coreSDK;
  final MatrixService _matrixService;

  Future<String?> resolve({
    required String receiverDid,
    required String matrixUserId,
  }) async {
    final channel = await _coreSDK.findChannelByDidOrNull(receiverDid);
    if (channel == null) return null;

    final serverName = _matrixService.homeserver.host;
    final candidates = [receiverDid, ...await fetchParticipantDids(channel)];
    return resolveSenderDidFromCandidates(
      matrixUserId: matrixUserId,
      serverName: serverName,
      candidateDids: candidates,
    );
  }

  Future<List<String>> fetchParticipantDids(Channel channel) async {
    if (channel.type == ChannelType.group) {
      final group = await _coreSDK.getGroupByOfferLink(channel.offerLink);
      if (group == null) return [];
      return group.members.map((m) => m.did).toList();
    }
    final peer = channel.otherPartyPermanentChannelDid;
    if (peer != null) return [peer];
    return [];
  }
}
