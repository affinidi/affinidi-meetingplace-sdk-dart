import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_group_details_update_body.dart';

export 'chat_group_details_update_body.dart';

class ChatGroupDetailsUpdate extends PlainTextMessage {
  ChatGroupDetailsUpdate({
    required super.id,
    required super.from,
    required super.to,
    required String groupId,
    required String groupDid,
    required String offerLink,
    required List<ChatGroupDetailsUpdateBodyMember> members,
    required List<String> adminDids,
    required DateTime dateCreated,
    required String groupPublicKey,
    String? groupKeyPair,
  }) : super(
          type: Uri.parse(ChatProtocol.chatGroupDetailsUpdate.value),
          body: ChatGroupDetailsUpdateBody(
            groupId: groupId,
            groupDid: groupDid,
            offerLink: offerLink,
            members: members,
            adminDids: adminDids,
            dateCreated: dateCreated,
            groupPublicKey: groupPublicKey,
            groupKeyPair: groupKeyPair,
          ).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory ChatGroupDetailsUpdate.create({
    required String from,
    required List<String> to,
    required String groupId,
    required String groupDid,
    required String offerLink,
    required List<ChatGroupDetailsUpdateBodyMember> members,
    required List<String> adminDids,
    required DateTime dateCreated,
    required String groupPublicKey,
    String? groupKeyPair,
  }) {
    return ChatGroupDetailsUpdate(
      id: const Uuid().v4(),
      from: from,
      to: to,
      groupId: groupId,
      groupDid: groupDid,
      offerLink: offerLink,
      members: members,
      adminDids: adminDids,
      dateCreated: dateCreated,
      groupKeyPair: groupKeyPair,
      groupPublicKey: groupPublicKey,
    );
  }

  // TODO: move factory methods to extensions to keep protocol clean ->
  // apply for all
  static ChatGroupDetailsUpdate fromGroup(
    Group group, {
    required String senderDid,
  }) {
    return ChatGroupDetailsUpdate.create(
      from: senderDid,
      to: [group.did],
      groupId: group.id,
      groupDid: group.did,
      offerLink: group.offerLink,
      members: group.members.map(fromGroupMember).toList(),
      adminDids: [group.ownerDid!],
      dateCreated: group.created,
      groupPublicKey: group.publicKey!,
    );
  }

  static ChatGroupDetailsUpdateBodyMember fromGroupMember(
    GroupMember groupMember,
  ) {
    return ChatGroupDetailsUpdateBodyMember(
      did: groupMember.did,
      vCard: groupMember.vCard,
      dateAdded: groupMember.dateAdded,
      status: groupMember.status.name,
      publicKey: groupMember.publicKey,
      membershipType: groupMember.membershipType.name,
    );
  }
}
