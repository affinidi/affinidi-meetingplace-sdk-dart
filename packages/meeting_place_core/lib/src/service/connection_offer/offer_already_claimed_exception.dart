class OfferAlreadyClaimedException implements Exception {
  final String message = 'Offer already claimed by claiming party.';

  @override
  String toString() => 'FindOfferOwnerException: $message)';
}
