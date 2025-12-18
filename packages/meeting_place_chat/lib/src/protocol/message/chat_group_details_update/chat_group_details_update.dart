import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_group_details_update_body.dart';

export 'chat_group_details_update_body.dart';

class ChatGroupDetailsUpdate {
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
      body: ChatGroupDetailsUpdateBody(
        groupId: groupId,
        groupDid: groupDid,
        offerLink: offerLink,
        members: members,
        adminDids: adminDids,
        dateCreated: dateCreated,
        groupPublicKey: groupPublicKey,
        groupKeyPair: groupKeyPair,
      ),
    );
  }

  factory ChatGroupDetailsUpdate.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return ChatGroupDetailsUpdate(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: ChatGroupDetailsUpdateBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  ChatGroupDetailsUpdate({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final ChatGroupDetailsUpdateBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(ChatProtocol.chatGroupDetailsUpdate.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
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
      contactCard: groupMember.contactCard,
      dateAdded: groupMember.dateAdded,
      status: groupMember.status.name,
      publicKey: groupMember.publicKey,
      membershipType: groupMember.membershipType.name,
    );
  }
}
