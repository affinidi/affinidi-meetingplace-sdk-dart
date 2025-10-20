class OfferOwnerException implements Exception {
  final String message =
      'Failed to claim offer because claiming party is the owner.';

  @override
  String toString() => 'FindOfferOwnerException: $message)';
}
