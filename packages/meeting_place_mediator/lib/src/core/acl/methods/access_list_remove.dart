import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'access_list_remove.g.dart';

/// [AccessListRemove] is an action type of [AclBody] which revokes existing
/// permissions from specified entities.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListRemove implements AclBody {
  /// Deserializes an [AccessListRemove] from its JSON representation.
  factory AccessListRemove.fromJson(Map<String, dynamic> json) {
    return _$AccessListRemoveFromJson(json);
  }

  /// Creates an [AccessListRemove], hashing [ownerDid] and [granteeDids]
  /// before storing them.
  AccessListRemove({
    required String ownerDid,
    required List<String> granteeDids,
  }) {
    this.ownerDid = hashDid(ownerDid);
    this.granteeDids = hashDids(granteeDids);
  }

  /// The ACL method identifier used when serializing this action.
  static final method = 'access_list_remove';

  /// The hash of the owner's DID.
  @JsonKey(name: 'did_hash')
  late final String ownerDid;

  /// The hashes of the grantee DIDs being revoked access.
  @JsonKey(name: 'hashes')
  late final List<String> granteeDids;

  /// Serializes the [AccessListRemove] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of revoked permissions.
  @override
  Map<String, dynamic> toJson() {
    return {method: _$AccessListRemoveToJson(this)};
  }
}
