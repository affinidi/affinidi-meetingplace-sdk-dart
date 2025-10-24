import 'package:json_annotation/json_annotation.dart';

part 'invitation_accept.g.dart';

/// Notification event for when a user has accepted an invitation to connect,
/// such as for a 1:1 chat or contact request.
///
/// Typical handling includes:
/// - Adding or updating the contact
/// - Finalizing the connection
/// - Notifying the user of the successful acceptance
@JsonSerializable(includeIfNull: false, createToJson: false)
class InvitationAccept {
  InvitationAccept({
    required this.id,
    required this.acceptOfferAsDid,
    required this.offerLink,
    this.pendingCount = 0,
    this.isEmpty = false,
  });
  final String id;

  @JsonKey(name: 'did')
  final String acceptOfferAsDid;
  final String offerLink;
  final bool isEmpty;
  final int pendingCount;

  static InvitationAccept fromJson(Map<String, dynamic> json) {
    return _$InvitationAcceptFromJson(json);
  }
}
