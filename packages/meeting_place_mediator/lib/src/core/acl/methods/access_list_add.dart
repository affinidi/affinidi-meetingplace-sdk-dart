import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'access_list_add.g.dart';

/// [AccessListAdd] is an action type of [acl] which grants new permissions to specified entities.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListAdd implements AclBody {
  factory AccessListAdd.fromJson(Map<String, dynamic> json) {
    return _$AccessListAddFromJson(json);
  }

  AccessListAdd({required String ownerDid, required List<String> granteeDids}) {
    this.ownerDid = hashDid(ownerDid);
    this.granteeDids = hashDids(granteeDids);
  }
  static final method = 'access_list_add';

  @JsonKey(name: 'did_hash')
  late final String ownerDid;

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
