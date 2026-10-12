import 'package:didcomm/didcomm.dart';

import '../acl_hashing_utils.dart';

/// Whether an [AccessListChange] grants or revokes access.
enum AccessListOperation { add, remove }

/// The owner and grantees of an access-list change, as hashes and, unless
/// created from JSON, as DIDs.
class AccessListChange {
  /// Creates an [AccessListChange], hashing [ownerDid] and [granteeDids].
  AccessListChange.fromDids({
    required String ownerDid,
    required List<String> granteeDids,
  }) : ownerDidHash = hashDid(ownerDid),
       granteeDidHashes = hashDids(granteeDids),
       _ownerDid = ownerDid,
       _granteeDids = List.unmodifiable(granteeDids);

  /// Creates an [AccessListChange] from its JSON representation, which only
  /// holds hashes.
  AccessListChange.fromJson(Map<String, dynamic> json)
    : ownerDidHash = json['did_hash'] as String,
      granteeDidHashes = (json['hashes'] as List<dynamic>).cast<String>(),
      _ownerDid = null,
      _granteeDids = null;

  /// The hash of the owner's DID.
  final String ownerDidHash;

  /// The hashes of the grantee DIDs.
  final List<String> granteeDidHashes;

  final String? _ownerDid;
  final List<String>? _granteeDids;

  /// Serializes the [AccessListChange] into a JSON object.
  Map<String, dynamic> toJson() {
    return {'did_hash': ownerDidHash, 'hashes': granteeDidHashes};
  }

  /// Builds a `messaging/access-list/update` Trust Task that applies
  /// [operation] to the grantees' access to the owner's inbox.
  ///
  /// Returns `null` if there are no grantees.
  TrustTaskDocument? toTrustTask({
    required String issuer,
    required String mediatorDid,
    required AccessListOperation operation,
  }) {
    if (granteeDidHashes.isEmpty) return null;

    final ownerDid = _ownerDid;
    final granteeDids = _granteeDids;

    if (ownerDid == null || granteeDids == null) {
      // Created from JSON: AccessListUpdateTask would hash the hashes again.
      return TrustTaskDocument(
        type: AccessListUpdateTask.taskType,
        issuer: issuer,
        recipient: mediatorDid,
        payload: {'did': ownerDidHash, operation.name: granteeDidHashes},
      );
    }

    return AccessListUpdateTask(
      issuer: issuer,
      mediatorDid: mediatorDid,
      targetDid: ownerDid,
      add: operation == AccessListOperation.add ? granteeDids : const [],
      remove: operation == AccessListOperation.remove ? granteeDids : const [],
    );
  }
}
