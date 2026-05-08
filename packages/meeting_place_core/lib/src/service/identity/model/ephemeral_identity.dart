import 'package:ssi/ssi.dart';

/// Represents an ephemeral identity used for a single connection.
///
/// This is used to create a DID that is only used for the duration of a
/// connection setup.
class EphemeralIdentity {
  /// Creates an [EphemeralIdentity] with the given [didManager] and
  /// [didDocument].
  EphemeralIdentity({required this.didManager, required this.didDocument});

  /// The [DidManager] that manages the ephemeral DID for this identity.
  final DidManager didManager;

  /// The [DidDocument] associated with the ephemeral DID.
  final DidDocument didDocument;
}
