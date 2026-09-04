import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'acl_set.g.dart';

/// [AccessListSet] is an action type of [AclBody] which replaces the entire
/// ACL with the provided permissions.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListSet implements AclBody {
  AccessListSet({required String ownerDid, required this.acls}) {
    this.ownerDid = hashDid(ownerDid);
  }

  factory AccessListSet.fromJson(Map<String, dynamic> json) {
    return _$AccessListSetFromJson(json);
  }

  factory AccessListSet.toPublic({required String ownerDid}) {
    return AccessListSet(ownerDid: ownerDid, acls: publicAclFlag);
  }

  static final publicAclFlag = 524283;
  static final method = 'acl_set';

  @JsonKey(name: 'did_hash')
  late final String ownerDid;

  final int acls;

  /// Serializes the [AccessListSet] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the permissions to be set.
  @override
  Map<String, dynamic> toJson() {
    return {method: _$AccessListSetToJson(this)};
  }
}
