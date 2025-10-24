class ChatUtils {
  static String getChatId({
    required String did,
    required String otherPartyDid,
  }) {
    return '$did-$otherPartyDid';
  }
}
