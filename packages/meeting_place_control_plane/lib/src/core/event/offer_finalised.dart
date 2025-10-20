import 'package:json_annotation/json_annotation.dart';

part 'offer_finalised.g.dart';

/// Notification event indicating that an invitation or offer has been finalized,
/// such as when both parties have accepted.
///
/// Typical handling:
/// - Finalize the connection
/// - Update the user interface
/// - Clean up any temporary data related to the offer
@JsonSerializable(explicitToJson: true, createToJson: false)
class OfferFinalised {
  OfferFinalised({
    required this.id,
    required this.offerLink,
    required this.notificationToken,
    this.pendingCount = 0,
    this.isEmpty = false,
  });
  final String id;
  final String offerLink;
  final String notificationToken;
  final int pendingCount;
  final bool isEmpty;

  static OfferFinalised fromJson(Map<String, dynamic> json) {
    return _$OfferFinalisedFromJson(json);
  }
}
