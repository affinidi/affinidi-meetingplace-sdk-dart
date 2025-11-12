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

  @JsonKey(name: 'groupId')
  final String groupId;

  @JsonKey(name: 'groupDid')
  final String groupDid;

  @JsonKey(name: 'offerLink')
  final String offerLink;

  @JsonKey(name: 'members')
  final List<ChatGroupDetailsUpdateBodyMember> members;

  @JsonKey(name: 'adminDids')
  final List<String> adminDids;

  @JsonKey(name: 'dateCreated')
  final DateTime dateCreated;

  @JsonKey(name: 'groupPublicKey')
  final String groupPublicKey;

  @JsonKey(name: 'groupKeyPair')
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

  final String did;
  final VCard vCard;
  final DateTime dateAdded;
  final String status;
  final String publicKey;
  final String membershipType;

  Map<String, dynamic> toJson() {
    return _$ChatGroupDetailsUpdateBodyMemberToJson(this);
  }
}
