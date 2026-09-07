import 'package:json_annotation/json_annotation.dart';

part 'invitation_outreach.g.dart';

/// Notification event indicating that a user has sent an outreach invitation,
/// such as a broadcast or service invitation (not a direct chat).
///
/// Typical handling:
/// - Show outreach notification
/// - Allow user to respond
@JsonSerializable(includeIfNull: false, createToJson: false)
class InvitationOutreach {
  /// Creates a new instance of [InvitationOutreach].
  InvitationOutreach({
    required this.id,
    required this.offerLink,
    required this.pendingCount,
  });

  /// The unique identifier of this event.
  final String id;

  /// A link identifying the outreach offer that was sent.
  final String offerLink;

  /// The number of pending, unprocessed outreach items.
  final int pendingCount;

  /// Creates an [InvitationOutreach] from the given JSON [json].
  static InvitationOutreach fromJson(Map<String, dynamic> json) {
    return _$InvitationOutreachFromJson(json);
  }
}
