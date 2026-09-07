import 'package:json_annotation/json_annotation.dart';

part 'invitation_group_accept.g.dart';

/// Notification event indicating that a user has accepted an invitation to join
/// a group.
///
/// Typical handling:
/// - Add the user to the group
/// - Update the group's membership list
/// - Notify the group admin if necessary
@JsonSerializable(includeIfNull: false, createToJson: false)
class InvitationGroupAccept {
  /// Creates a new instance of [InvitationGroupAccept].
  InvitationGroupAccept({
    required this.id,
    required this.acceptOfferAsDid,
    required this.offerLink,
    this.isEmpty = false,
    this.pendingCount = 0,
  });

  /// The unique identifier of this event.
  final String id;

  /// The DID that accepted the group invitation.
  @JsonKey(name: 'did')
  final String acceptOfferAsDid;

  /// A link identifying the group offer that was accepted.
  final String offerLink;

  /// Whether there is no pending acceptance data to report.
  final bool isEmpty;

  /// The number of pending, unprocessed acceptance items.
  final int pendingCount;

  /// Creates an [InvitationGroupAccept] from the given JSON [json].
  static InvitationGroupAccept fromJson(Map<String, dynamic> json) {
    return _$InvitationGroupAcceptFromJson(json);
  }
}
