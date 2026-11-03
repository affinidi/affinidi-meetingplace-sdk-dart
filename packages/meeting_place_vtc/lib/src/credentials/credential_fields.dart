/// Reads the members of a JSON verifiable credential this wallet checks:
/// who issued it, about whom, and what kind it is. Each accepts both the
/// plain and the object form the data model allows.
library;

/// The credential's issuer DID, from `issuer` or `issuer.id`.
String? credentialIssuer(Map<String, dynamic> credential) {
  return switch (credential['issuer']) {
    final String id => id,
    {'id': final String id} => id,
    _ => null,
  };
}

/// The ids of the credential's subjects.
Set<String> credentialSubjects(Map<String, dynamic> credential) {
  final subject = credential['credentialSubject'];
  final subjects = subject is List ? subject : [subject];
  return {
    for (final entry in subjects)
      if (entry case {'id': final String id}) id,
  };
}

/// The credential's types, from `type` as a string or a list.
Set<String> credentialTypes(Map<String, dynamic> credential) {
  return switch (credential['type']) {
    final String type => {type},
    final List<dynamic> types => types.whereType<String>().toSet(),
    _ => const {},
  };
}
