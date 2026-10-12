import 'package:didcomm/didcomm.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';
import '../legacy_acl_bitmask.dart';
import '../trust_task_acl_body.dart';

/// [AccessListSet] is an action type of [AclBody] which changes the owner's
/// access-list mode on the mediator.
///
/// Mediators that serve the ACL Trust Tasks no longer accept ACL bitmasks,
/// and the access-list mode is the only flag a DID may change itself. Only
/// the access-list mode bit of [acls] is applied there; all other bits are
/// ignored. Older mediators receive the full bitmask with acl-management.
class AccessListSet implements TrustTaskAclBody {
  /// Creates an [AccessListSet], hashing [ownerDid] and applying the
  /// access-list mode of [acls].
  AccessListSet({required String ownerDid, required int acls})
    : this._(ownerDid: hashDid(ownerDid), acls: acls, plainOwnerDid: ownerDid);

  AccessListSet._({
    required this.ownerDid,
    required this.acls,
    String? plainOwnerDid,
  }) : _plainOwnerDid = plainOwnerDid;

  /// Deserializes an [AccessListSet] from its JSON representation.
  @Deprecated(
    'Only the hash of the owner DID is serialized, so the DID needed by the '
    'didcomm Trust Task classes is lost. Create an AccessListSet from the DID '
    'instead.',
  )
  factory AccessListSet.fromJson(Map<String, dynamic> json) {
    return AccessListSet._(
      ownerDid: json['did_hash'] as String,
      acls: (json['acls'] as num).toInt(),
    );
  }

  /// Creates an [AccessListSet] that lets any DID message [ownerDid] by
  /// switching its access list to explicit deny.
  factory AccessListSet.toPublic({required String ownerDid}) {
    return AccessListSet(ownerDid: ownerDid, acls: publicAclFlag);
  }

  /// The legacy ACL bitmask that grants public access.
  static final publicAclFlag = 524283;

  /// The ACL method identifier used when serializing this action.
  static final method = 'acl_set';

  /// The hash of the owner's DID.
  final String ownerDid;

  /// The legacy ACL bitmask whose access-list mode is applied.
  final int acls;

  // The owner DID itself, unknown when created from JSON.
  final String? _plainOwnerDid;

  /// Serializes the [AccessListSet] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the permissions to be set.
  @override
  Map<String, dynamic> toJson() {
    return {
      method: {'did_hash': ownerDid, 'acls': acls},
    };
  }

  /// Builds a `messaging/account/update` Trust Task that sets the owner's
  /// access-list mode.
  @override
  TrustTaskDocument toTrustTask({
    required String issuer,
    required String mediatorDid,
  }) {
    final acl = MediatorAcl(
      accessListMode: accessListModeFromLegacyBitmask(acls),
    );
    final plainOwnerDid = _plainOwnerDid;

    if (plainOwnerDid == null) {
      // Created from JSON: AccountUpdateTask would hash the hash again.
      return TrustTaskDocument(
        type: AccountUpdateTask.taskType,
        issuer: issuer,
        recipient: mediatorDid,
        payload: {'did': ownerDid, 'acl': acl.toJson()},
      );
    }

    return AccountUpdateTask(
      issuer: issuer,
      mediatorDid: mediatorDid,
      targetDid: plainOwnerDid,
      acl: acl,
    );
  }
}
