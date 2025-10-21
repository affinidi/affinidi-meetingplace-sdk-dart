import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'access_list_remove.g.dart';

/// [AccessListRemove] is an action type of [acl] which revokes existing permissions
/// from specified entities.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListRemove implements AclBody {
  factory AccessListRemove.fromJson(Map<String, dynamic> json) {
    return _$AccessListRemoveFromJson(json);
  }

  AccessListRemove({
    required String ownerDid,
    required List<String> granteeDids,
  }) {
    this.ownerDid = hashDid(ownerDid);
    this.granteeDids = hashDids(granteeDids);
  }
  static final method = 'access_list_remove';

  @JsonKey(name: 'did_hash')
  late final String ownerDid;

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
