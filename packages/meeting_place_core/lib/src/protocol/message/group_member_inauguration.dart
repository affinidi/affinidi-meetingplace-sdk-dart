import 'package:didcomm/didcomm.dart';
import '../attachment/attachment_format.dart';
import '../attachment/attachment_media_type.dart';
import '../meeting_place_protocol.dart';
import '../../entity/contact_card.dart';
import 'package:uuid/uuid.dart';

class GroupMemberInaugurationMember {
  GroupMemberInaugurationMember({
    required this.did,
    required this.contactCard,
    required this.membershipType,
    required this.status,
    required this.publicKey,
  });

  final String did;
  final ContactCard contactCard;
  final String membershipType;
  final String status;
  final String publicKey;

  bool isAdmin() => membershipType == 'admin';

  bool isMember() => membershipType == 'member';
}

class GroupMemberInauguration extends PlainTextMessage {
  GroupMemberInauguration({
    required super.id,
    required super.from,
    required super.to,
    required this.memberDid,
    required this.groupDid,
    required this.groupId,
    required this.groupPublicKey,
    required this.adminDids,
    required this.members,
    this.card,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.groupMemberInauguration.value),
          body: {
            'memberDid': memberDid,
            'groupDid': groupDid,
            'groupId': groupId,
            'groupPublicKey': groupPublicKey,
            'adminDids': adminDids,
            'members': members
                .map(
                  (m) => {
                    'did': m.did,
                    'card': m.contactCard.toJson(),
                    'status': m.status,
                    'publicKey': m.publicKey,
                    'isAdmin': (m.isAdmin()).toString(),
                  },
                )
                .toList(),
          },
          createdTime: DateTime.now().toUtc(),
          attachments: [
            Attachment(
              id: const Uuid().v4(),
              format: AttachmentFormat.contactCard.value,
              mediaType: AttachmentMediaType.textContactCard.value,
              description: 'ContactCard Info',
              data: AttachmentData(base64: card?.toBase64()),
            ),
          ],
        );

  factory GroupMemberInauguration.create({
    required String from,
    required List<String> to,
    required String memberDid,
    required String groupDid,
    required String groupId,
    required String groupPublicKey,
    required List<String> adminDids,
    required List<GroupMemberInaugurationMember> members,
  }) {
    return GroupMemberInauguration(
      id: Uuid().v4(),
      from: from,
      to: to,
      memberDid: memberDid,
      groupDid: groupDid,
      groupId: groupId,
      adminDids: adminDids,
      groupPublicKey: groupPublicKey,
      members: members,
    );
  }

  factory GroupMemberInauguration.fromMessage(PlainTextMessage message) {
    return GroupMemberInauguration(
      id: message.id,
      from: message.from,
      to: message.to,
      adminDids: List<String>.from(message.body!['adminDids'] as List<dynamic>),
      memberDid: message.body!['memberDid'] as String,
      groupId: message.body!['groupId'] as String,
      groupDid: message.body!['groupDid'] as String,
      groupPublicKey: message.body!['groupPublicKey'] as String,
      members: (message.body!['members'] as List<dynamic>).map((member) {
        final memberData = member as Map<String, dynamic>;
        return GroupMemberInaugurationMember(
          did: memberData['did'] as String,
          contactCard:
              ContactCard.fromJson(memberData['card'] as Map<String, dynamic>),
          status: memberData['status'],
          publicKey: memberData['publicKey'] as String,
          membershipType: memberData['isAdmin'] == 'true' ? 'admin' : 'member',
        );
      }).toList(),
    );
  }

  final String memberDid;
  final String groupDid;
  final String groupId;
  final String groupPublicKey;
  final List<String> adminDids;
  final List<GroupMemberInaugurationMember> members;
  final ContactCard? card;
}
