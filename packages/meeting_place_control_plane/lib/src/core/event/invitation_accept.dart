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
  /// Creates a new instance of [InvitationAccept].
  InvitationAccept({
    required this.id,
    required this.acceptOfferAsDid,
    required this.offerLink,
    this.pendingCount = 0,
    this.isEmpty = false,
  });

  /// The unique identifier of this event.
  final String id;

  /// The DID that accepted the offer.
  @JsonKey(name: 'did')
  final String acceptOfferAsDid;

  /// A link identifying the offer that was accepted.
  final String offerLink;

  /// Whether there is no pending acceptance data to report.
  final bool isEmpty;

  /// The number of pending, unprocessed acceptance items.
  final int pendingCount;

  /// Creates an [InvitationAccept] from the given JSON [json].
  static InvitationAccept fromJson(Map<String, dynamic> json) {
    return _$InvitationAcceptFromJson(json);
  }
}
