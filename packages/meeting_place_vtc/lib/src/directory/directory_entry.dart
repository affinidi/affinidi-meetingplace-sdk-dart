/// One member's directory entry, as the community projects it for the
/// caller: a field the member does not show the caller is null.
class DirectoryEntry {
  /// Creates a [DirectoryEntry].
  const DirectoryEntry({
    required this.entryId,
    this.displayName,
    this.nickname,
    this.did,
    this.role,
    this.avatarSha256,
    this.isConnected = false,
  });

  /// Reads [entry], an entry of `entries/list` or `entries/show`, or null
  /// when it has no entry id.
  static DirectoryEntry? read(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final entryId = entry['entryId'];
    if (entryId is! String) return null;
    final fields = entry['fields'] is Map<String, dynamic>
        ? entry['fields'] as Map<String, dynamic>
        : const <String, dynamic>{};
    String? text(String key) =>
        fields[key] is String ? fields[key] as String : null;
    return DirectoryEntry(
      entryId: entryId,
      displayName: text('displayName'),
      nickname: text('nickname'),
      did: text('did'),
      role: text('role'),
      avatarSha256: switch (fields['avatar']) {
        {'sha256': final String sha256} => sha256,
        _ => null,
      },
      isConnected: entry['connected'] == true,
    );
  }

  /// The community's id of the entry, stable while the member stays.
  final String entryId;

  /// The member's name, when they show it to the caller.
  final String? displayName;

  /// The member's nickname, when they show it to the caller.
  final String? nickname;

  /// The DID the member joined with, when they show it to the caller.
  final String? did;

  /// The member's role in the community, such as `member`, `admin` or
  /// `custom:<name>`, when the community shows it to the caller.
  final String? role;

  /// The digest of the member's picture, when they show it to the caller:
  /// it names the picture to fetch, and stays the same while it does.
  final String? avatarSha256;

  /// Whether the caller and the member vouched for one another, either way
  /// round, as the community sees it.
  final bool isConnected;
}

/// The caller's own directory card, as far as vouching needs it.
class MyDirectoryCard {
  /// Creates a [MyDirectoryCard].
  const MyDirectoryCard({
    required this.entryId,
    required this.isDidVisibleToMembers,
    this.displayName,
    this.isHidden = false,
    this.avatarSha256,
  });

  /// The id of the caller's own entry.
  final String entryId;

  /// The name other members see, if the caller gave one.
  final String? displayName;

  /// Whether the card is hidden from every member, so no member can find
  /// the caller, whatever else it shows.
  final bool isHidden;

  /// The digest of the picture on the card, if it holds one.
  final String? avatarSha256;

  /// Whether other members can find the caller to vouch for them: the card
  /// is not hidden, and shows them the DID the caller joined with.
  bool get isFindable => isDidVisibleToMembers && !isHidden;

  /// Whether other members see the DID the caller joined with, so they can
  /// find the caller to vouch for them.
  final bool isDidVisibleToMembers;
}
