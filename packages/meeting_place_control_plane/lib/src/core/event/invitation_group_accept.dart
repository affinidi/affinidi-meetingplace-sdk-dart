import 'package:json_annotation/json_annotation.dart';

part 'invitation_group_accept.g.dart';

/// Notification event indicating that a user has accepted an invitation to join a group.
///
/// Typical handling:
/// - Add the user to the group
/// - Update the group's membership list
/// - Notify the group admin if necessary
@JsonSerializable(includeIfNull: false, createToJson: false)
class InvitationGroupAccept {
  InvitationGroupAccept({
    required this.id,
    required this.acceptOfferAsDid,
    required this.offerLink,
    this.isEmpty = false,
    this.pendingCount = 0,
  });
  final String id;

  @JsonKey(name: 'did')
  final String acceptOfferAsDid;
  final String offerLink;
  final bool isEmpty;
  final int pendingCount;

  static InvitationGroupAccept fromJson(Map<String, dynamic> json) {
    return _$InvitationGroupAcceptFromJson(json);
  }
}
