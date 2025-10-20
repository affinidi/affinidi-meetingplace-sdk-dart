class MpxRepositoryException implements Exception {
  MpxRepositoryException(this.message, {required this.type});

  final String message;
  final String type;
}
