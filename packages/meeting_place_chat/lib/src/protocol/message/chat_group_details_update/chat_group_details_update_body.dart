import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

part 'chat_group_details_update_body.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ChatGroupDetailsUpdateBody {
  factory ChatGroupDetailsUpdateBody.fromJson(Map<String, dynamic> json) =>
      _$ChatGroupDetailsUpdateBodyFromJson(json);

  ChatGroupDetailsUpdateBody({
    required this.groupId,
    required this.groupDid,
    required this.offerLink,
    required this.members,
    required this.adminDids,
    required this.dateCreated,
    required this.groupPublicKey,
    this.groupKeyPair,
  });

  @JsonKey(name: 'group_id')
  final String groupId;

  @JsonKey(name: 'group_did')
  final String groupDid;

  @JsonKey(name: 'offer_link')
  final String offerLink;

  @JsonKey(name: 'members')
  final List<ChatGroupDetailsUpdateBodyMember> members;

  @JsonKey(name: 'admin_dids')
  final List<String> adminDids;

  @JsonKey(name: 'date_created')
  final DateTime dateCreated;

  @JsonKey(name: 'group_public_key')
  final String groupPublicKey;

  @JsonKey(name: 'group_key_pair')
  final String? groupKeyPair;

  Map<String, dynamic> toJson() => _$ChatGroupDetailsUpdateBodyToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ChatGroupDetailsUpdateBodyMember {
  factory ChatGroupDetailsUpdateBodyMember.fromJson(
          Map<String, dynamic> json) =>
      _$ChatGroupDetailsUpdateBodyMemberFromJson(json);

  ChatGroupDetailsUpdateBodyMember({
    required this.did,
    required this.vCard,
    required this.dateAdded,
    required this.status,
    required this.publicKey,
    required this.membershipType,
  });

  @JsonKey(name: 'did')
  final String did;

  @JsonKey(name: 'v_card')
  final VCard vCard;

  @JsonKey(name: 'date_added')
  final DateTime dateAdded;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'public_key')
  final String publicKey;

  @JsonKey(name: 'membership_type')
  final String membershipType;

  Map<String, dynamic> toJson() {
    return _$ChatGroupDetailsUpdateBodyMemberToJson(this);
  }
}
