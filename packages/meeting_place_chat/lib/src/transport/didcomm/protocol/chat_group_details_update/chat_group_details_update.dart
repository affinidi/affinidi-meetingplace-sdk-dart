import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../chat_protocol.dart';
import 'chat_group_details_update_body.dart';

export 'chat_group_details_update_body.dart';

/// A DIDComm message broadcasting a group's current details (membership,
/// admins, group DID/key material) to its participants.
///
/// Sent locally via [ChatGroupDetailsUpdate.create] or [fromGroup], or
/// reconstructed from an incoming `PlainTextMessage` via
/// [ChatGroupDetailsUpdate.fromPlainTextMessage].
class ChatGroupDetailsUpdate {
  /// Creates a new outgoing [ChatGroupDetailsUpdate] with a freshly
  /// generated [id] and the given group details as its [body].
  factory ChatGroupDetailsUpdate.create({
    required String from,
    required List<String> to,
    required String groupId,
    required String groupDid,
    required String offerLink,
    required List<ChatGroupDetailsUpdateBodyMember> members,
    required List<String> adminDids,
    required DateTime dateCreated,
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
        groupKeyPair: groupKeyPair,
      ),
    );
  }

  /// Reconstructs a [ChatGroupDetailsUpdate] from an incoming
  /// `PlainTextMessage`.
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

  /// Creates a [ChatGroupDetailsUpdate] with the given parameters.
  /// [createdTime] defaults to now (UTC) when omitted.
  ChatGroupDetailsUpdate({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  /// Unique identifier of this message.
  final String id;

  /// DID of the sender.
  final String from;

  /// DIDs of the recipients.
  final List<String> to;

  /// The group's details carried by this update.
  final ChatGroupDetailsUpdateBody body;

  /// When this update was created.
  final DateTime createdTime;

  /// Converts this update into a `PlainTextMessage` ready to be sent over
  /// DIDComm.
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
  /// Builds a [ChatGroupDetailsUpdate] from the current state of [group],
  /// addressed to the group and sent by [senderDid].
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
      members: group.members.map(_fromGroupMember).toList(),
      adminDids: [group.ownerDid!],
      dateCreated: group.created,
    );
  }

  static ChatGroupDetailsUpdateBodyMember _fromGroupMember(
    GroupMember groupMember,
  ) {
    return ChatGroupDetailsUpdateBodyMember(
      did: groupMember.did,
      contactCard: ContactCard(
        did: groupMember.did,
        type: groupMember.contactCard.type,
        contactInfo: {},
      ),
      dateAdded: groupMember.dateAdded,
      status: groupMember.status.name,
      membershipType: groupMember.membershipType.name,
    );
  }
}
