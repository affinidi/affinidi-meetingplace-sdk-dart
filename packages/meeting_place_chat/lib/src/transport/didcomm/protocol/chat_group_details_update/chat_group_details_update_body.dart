import 'package:json_annotation/json_annotation.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

part 'chat_group_details_update_body.g.dart';

/// The body of a `ChatGroupDetailsUpdate`: the group's identity, membership,
/// and offer/key material as of when the update was sent.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ChatGroupDetailsUpdateBody {
  /// Deserializes a [ChatGroupDetailsUpdateBody] from its wire JSON.
  factory ChatGroupDetailsUpdateBody.fromJson(Map<String, dynamic> json) =>
      _$ChatGroupDetailsUpdateBodyFromJson(json);

  /// Creates a [ChatGroupDetailsUpdateBody] with the given parameters.
  ChatGroupDetailsUpdateBody({
    required this.groupId,
    required this.groupDid,
    required this.offerLink,
    required this.members,
    required this.adminDids,
    required this.dateCreated,
    this.groupKeyPair,
  });

  /// Unique identifier of the group.
  @JsonKey(name: 'group_id')
  final String groupId;

  /// DID of the group.
  @JsonKey(name: 'group_did')
  final String groupDid;

  /// Link used to invite/offer new members into the group.
  @JsonKey(name: 'offer_link')
  final String offerLink;

  /// The group's current members.
  @JsonKey(name: 'members')
  final List<ChatGroupDetailsUpdateBodyMember> members;

  /// DIDs of the group's admins.
  @JsonKey(name: 'admin_dids')
  final List<String> adminDids;

  /// When the group was created.
  @JsonKey(name: 'date_created')
  final DateTime dateCreated;

  /// The group's key pair material, when applicable to the group's
  /// encryption scheme.
  @JsonKey(name: 'group_key_pair')
  final String? groupKeyPair;

  /// Serializes this body to its wire JSON.
  Map<String, dynamic> toJson() => _$ChatGroupDetailsUpdateBodyToJson(this);
}

/// A single member entry within a [ChatGroupDetailsUpdateBody].
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ChatGroupDetailsUpdateBodyMember {
  /// Deserializes a [ChatGroupDetailsUpdateBodyMember] from its wire JSON.
  factory ChatGroupDetailsUpdateBodyMember.fromJson(
    Map<String, dynamic> json,
  ) => _$ChatGroupDetailsUpdateBodyMemberFromJson(json);

  /// Creates a [ChatGroupDetailsUpdateBodyMember] with the given parameters.
  ChatGroupDetailsUpdateBodyMember({
    required this.did,
    required this.contactCard,
    required this.dateAdded,
    required this.status,
    required this.membershipType,
  });

  /// DID of the member.
  @JsonKey(name: 'did')
  final String did;

  /// The member's contact card.
  @JsonKey(name: 'contact_card')
  final ContactCard contactCard;

  /// When the member was added to the group.
  @JsonKey(name: 'date_added')
  final DateTime dateAdded;

  /// The member's membership status.
  @JsonKey(name: 'status')
  final String status;

  /// The member's membership type (e.g. admin vs regular member).
  @JsonKey(name: 'membership_type')
  final String membershipType;

  /// Serializes this member to its wire JSON.
  Map<String, dynamic> toJson() {
    return _$ChatGroupDetailsUpdateBodyMemberToJson(this);
  }
}
