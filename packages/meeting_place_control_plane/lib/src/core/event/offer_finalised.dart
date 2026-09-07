import 'package:json_annotation/json_annotation.dart';

part 'offer_finalised.g.dart';

/// Notification event indicating that an invitation or offer has been
/// finalized,
/// such as when both parties have accepted.
///
/// Typical handling:
/// - Finalize the connection
/// - Update the user interface
/// - Clean up any temporary data related to the offer
@JsonSerializable(explicitToJson: true, createToJson: false)
class OfferFinalised {
  /// Creates a new instance of [OfferFinalised].
  OfferFinalised({
    required this.id,
    required this.offerLink,
    required this.notificationToken,
    this.pendingCount = 0,
    this.isEmpty = false,
  });

  /// The unique identifier of this event.
  final String id;

  /// A link identifying the offer that was finalised.
  final String offerLink;

  /// The token identifying the notification this event was delivered as.
  final String notificationToken;

  /// The number of pending, unprocessed finalisation items.
  final int pendingCount;

  /// Whether there is no pending finalisation data to report.
  final bool isEmpty;

  /// Creates an [OfferFinalised] from the given JSON [json].
  static OfferFinalised fromJson(Map<String, dynamic> json) {
    return _$OfferFinalisedFromJson(json);
  }
}
