import 'package:ssi/ssi.dart';

/// Represents a permanent identity in the Meeting Place SDK,
/// which includes a DID managed by a [DidManager],
/// the associated [DidDocument], and the Matrix user ID for this identity.
class PermanentIdentity {
  PermanentIdentity({
    required this.didManager,
    required this.didDocument,
    this.matrixUserId,
  });

  /// The [DidManager] that manages the permanent DID for this identity.
  final DidManager didManager;

  /// The [DidDocument] associated with the permanent identity.
  final DidDocument didDocument;

  /// The Matrix user ID associated with the permanent identity.
  // TODO: Extend to its own object containing user id and homeserver?
  final String? matrixUserId;
}
