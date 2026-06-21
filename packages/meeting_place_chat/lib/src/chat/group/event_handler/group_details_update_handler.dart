import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../transport/matrix/outgoing/group_details_update_sender.dart';

class GroupDetailsUpdateHandler implements ChatEventHandler {
  GroupDetailsUpdateHandler({
    required MeetingPlaceCoreSDK coreSDK,
    required ChatRepository chatRepository,
    required ChatStream streamManager,
    required String chatId,
    required Group Function() getGroup,
    required void Function(Group) setGroup,
    required Future<Channel> Function() getChannel,
  }) : _coreSDK = coreSDK,
       _chatRepository = chatRepository,
       _streamManager = streamManager,
       _chatId = chatId,
       _getGroup = getGroup,
       _setGroup = setGroup,
       _getChannel = getChannel;

  final MeetingPlaceCoreSDK _coreSDK;
  final ChatRepository _chatRepository;
  final ChatStream _streamManager;
  final String _chatId;
  final Group Function() _getGroup;
  final void Function(Group) _setGroup;
  final Future<Channel> Function() _getChannel;

  @override
  Future<void> handle(IncomingChatEvent event) async {
    final updatedGroup = await _updateGroupMembers(
      group: _getGroup(),
      body: event.content,
      chatEvent: const ChatGroupDetailsUpdateEvent(),
    );
    await _coreSDK.updateGroup(updatedGroup);
    _setGroup(updatedGroup);
  }

  Future<Group> _updateGroupMembers({
    required Group group,
    required Map<String, dynamic> body,
    required ChatEvent chatEvent,
  }) async {
    final membersFromMessage = (body['members'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final attachedCards = await _downloadContactCards(body);

    final knownMembers = group.members.map((member) => member.did).toSet();
    final newMembers = membersFromMessage
        .where((member) {
          final status = GroupMemberStatus.values.byName(
            member['status'] as String,
          );
          return !knownMembers.contains(member['did']) &&
              status == GroupMemberStatus.approved;
        })
        .toList()
        .cast<Map<String, dynamic>>();

    for (final newMember in newMembers) {
      final did = newMember['did'] as String;
      final card = attachedCards[did] ?? _resolveContactCard(did, group);
      if (card == null) continue;
      final chatItem = await _chatRepository.createMessage(
        EventMessage.groupMemberJoined(
          chatId: _chatId,
          groupDid: group.did,
          memberDid: did,
          memberCard: card.toJson(),
        ),
      );
      _streamManager.pushData(StreamData(chatItem: chatItem));
    }

    final updatedGroup = group.copyWith(
      members: membersFromMessage.map((member) {
        final did = member['did'] as String;
        final contactCard =
            attachedCards[did] ?? _resolveContactCard(did, group);
        return GroupMember(
          did: did,
          dateAdded: DateTime.parse(member['date_added'] as String),
          status: GroupMemberStatus.values.byName(member['status'] as String),
          publicKey: member['public_key'] as String,
          membershipType: GroupMembershipType.values.byName(
            member['membership_type'] as String,
          ),
          contactCard: contactCard ??
              ContactCard(did: did, type: 'human', contactInfo: {}),
        );
      }).toList(),
    );

    _streamManager.pushData(StreamData(event: chatEvent));
    return updatedGroup;
  }

  Future<Map<String, ContactCard>> _downloadContactCards(
    Map<String, dynamic> body,
  ) async {
    final eventIds =
        body[GroupDetailsUpdateSender.contactCardEventIdsKey]
            as Map<String, dynamic>?;
    if (eventIds == null || eventIds.isEmpty) return {};

    final channel = await _getChannel();
    final cards = <String, ContactCard>{};
    for (final entry in eventIds.entries) {
      final did = entry.key;
      final eventId = entry.value as String;
      try {
        final bytes = await _coreSDK.downloadMedia(
          channel,
          MatrixEventMediaReference(eventId),
        );
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        cards[did] = ContactCard.fromJson(json);
      } catch (_) {
        // Card download failed — the member will keep its stub card.
      }
    }
    return cards;
  }

  ContactCard? _resolveContactCard(String did, Group group) {
    for (final member in group.members) {
      if (member.did == did) return member.contactCard;
    }
    return null;
  }
}
