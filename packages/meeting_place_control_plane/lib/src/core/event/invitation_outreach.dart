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
  InvitationOutreach({
    required this.id,
    required this.offerLink,
    required this.pendingCount,
  });
  final String id;
  final String offerLink;
  final int pendingCount;

  static InvitationOutreach fromJson(Map<String, dynamic> json) {
    return _$InvitationOutreachFromJson(json);
  }
}
