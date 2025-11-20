import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'acl_set.g.dart';

/// [AclSet] is an action type of `AclBody` which replaces the entire ACL
/// with the provided permissions.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AclSet implements AclBody {
  AclSet({required String ownerDid, required this.acls}) {
    this.ownerDid = hashDid(ownerDid);
  }

  factory AclSet.fromJson(Map<String, dynamic> json) {
    return _$AclSetFromJson(json);
  }

  factory AclSet.toPublic({required String ownerDid}) {
    return AclSet(ownerDid: ownerDid, acls: publicAclFlag);
  }

  static final publicAclFlag = 524283;
  static final method = 'acl_set';

  @JsonKey(name: 'did_hash')
  late final String ownerDid;

  final int acls;

  /// Serializes the [AclSet] into a JSON object.
  ///
  /// **Returns:**
  /// - A `Map<String, dynamic>` representation of the permissions to be set.
  @override
  Map<String, dynamic> toJson() {
    return {method: _$AclSetToJson(this)};
  }
}
