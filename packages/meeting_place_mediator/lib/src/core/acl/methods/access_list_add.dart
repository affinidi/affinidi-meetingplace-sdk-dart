import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'access_list_add.g.dart';

/// [AccessListAdd] is an action type of [AclBody] which grants new permissions
/// to specified entities.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListAdd implements AclBody {
  /// Deserializes an [AccessListAdd] from its JSON representation.
  factory AccessListAdd.fromJson(Map<String, dynamic> json) {
    return _$AccessListAddFromJson(json);
  }

  /// Creates an [AccessListAdd], hashing [ownerDid] and [granteeDids] before
  /// storing them.
  AccessListAdd({required String ownerDid, required List<String> granteeDids}) {
    this.ownerDid = hashDid(ownerDid);
    this.granteeDids = hashDids(granteeDids);
  }

  /// The ACL method identifier used when serializing this action.
  static final method = 'access_list_add';

  /// The hash of the owner's DID.
  @JsonKey(name: 'did_hash')
  late final String ownerDid;

  /// The hashes of the grantee DIDs being granted access.
  @JsonKey(name: 'hashes')
  late final List<String> granteeDids;

  /// Serializes the [AccessListAdd] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of granted permissions.
  @override
  Map<String, dynamic> toJson() {
    return {method: _$AccessListAddToJson(this)};
  }
}
