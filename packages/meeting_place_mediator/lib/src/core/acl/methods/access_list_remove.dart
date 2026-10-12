import 'package:didcomm/didcomm.dart';

import '../acl_body.dart';
import '../trust_task_acl_body.dart';
import 'access_list_change.dart';

/// [AccessListRemove] is an action type of [AclBody] which revokes existing
/// permissions from specified entities.
class AccessListRemove implements TrustTaskAclBody {
  /// Deserializes an [AccessListRemove] from its JSON representation.
  @Deprecated(
    'Only hashes are serialized, so the DIDs needed by the didcomm Trust '
    'Task classes are lost. Create an AccessListRemove from the DIDs instead.',
  )
  factory AccessListRemove.fromJson(Map<String, dynamic> json) {
    return AccessListRemove._(AccessListChange.fromJson(json));
  }

  /// Creates an [AccessListRemove], hashing [ownerDid] and [granteeDids] before
  /// storing them.
  AccessListRemove({
    required String ownerDid,
    required List<String> granteeDids,
  }) : this._(
         AccessListChange.fromDids(
           ownerDid: ownerDid,
           granteeDids: granteeDids,
         ),
       );

  AccessListRemove._(this._change);

  /// The ACL method identifier used when serializing this action.
  static final method = 'access_list_remove';

  final AccessListChange _change;

  /// The hash of the owner's DID.
  String get ownerDid => _change.ownerDidHash;

  /// The hashes of the grantee DIDs being revoked access.
  List<String> get granteeDids => _change.granteeDidHashes;

  /// Serializes the [AccessListRemove] into a JSON object.
  @override
  Map<String, dynamic> toJson() {
    return {method: _change.toJson()};
  }

  /// Builds a `messaging/access-list/update` Trust Task that revokes the
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
      operation: AccessListOperation.remove,
    );
  }
}
