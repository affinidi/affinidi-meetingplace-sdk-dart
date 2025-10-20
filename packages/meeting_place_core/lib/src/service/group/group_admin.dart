class GroupAdmin {
  GroupAdmin({
    required this.memberPublicKey,
    required this.memberReencryptionKey,
  });

  final String memberPublicKey;
  final String memberReencryptionKey;
}
