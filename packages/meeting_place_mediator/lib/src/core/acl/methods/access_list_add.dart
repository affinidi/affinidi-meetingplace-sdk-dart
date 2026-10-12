import 'package:didcomm/didcomm.dart';

import '../acl_body.dart';
import '../trust_task_acl_body.dart';
import 'access_list_change.dart';

/// [AccessListAdd] is an action type of [AclBody] which grants new permissions
/// to specified entities.
class AccessListAdd implements TrustTaskAclBody {
  /// Deserializes an [AccessListAdd] from its JSON representation.
  @Deprecated(
    'Only hashes are serialized, so the DIDs needed by the didcomm Trust '
    'Task classes are lost. Create an AccessListAdd from the DIDs instead.',
  )
  factory AccessListAdd.fromJson(Map<String, dynamic> json) {
    return AccessListAdd._(AccessListChange.fromJson(json));
  }

  /// Creates an [AccessListAdd], hashing [ownerDid] and [granteeDids] before
  /// storing them.
  AccessListAdd({required String ownerDid, required List<String> granteeDids})
    : this._(
        AccessListChange.fromDids(ownerDid: ownerDid, granteeDids: granteeDids),
      );

  AccessListAdd._(this._change);

  /// The ACL method identifier used when serializing this action.
  static final method = 'access_list_add';

  final AccessListChange _change;

  /// The hash of the owner's DID.
  String get ownerDid => _change.ownerDidHash;

  /// The hashes of the grantee DIDs being granted access.
  List<String> get granteeDids => _change.granteeDidHashes;

  /// Serializes the [AccessListAdd] into a JSON object.
  @override
  Map<String, dynamic> toJson() {
    return {method: _change.toJson()};
  }

  /// Builds a `messaging/access-list/update` Trust Task that grants the
  /// grantees' access to the owner's inbox.
  ///
  /// Returns `null` if there are no grantees.
  @override
  TrustTaskDocument? toTrustTask({
    required String issuer,
    required String mediatorDid,
  }) {
    return _change.toTrustTask(
      issuer: issuer,
      mediatorDid: mediatorDid,
      operation: AccessListOperation.add,
    );
  }
}
