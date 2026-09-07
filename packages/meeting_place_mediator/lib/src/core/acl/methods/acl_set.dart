import 'package:json_annotation/json_annotation.dart';

import '../acl_body.dart';
import '../acl_hashing_utils.dart';

part 'acl_set.g.dart';

/// [AccessListSet] is an action type of [AclBody] which replaces the entire
/// ACL with the provided permissions.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AccessListSet implements AclBody {
  /// Creates an [AccessListSet], hashing [ownerDid] and replacing the ACL
  /// with [acls].
  AccessListSet({required String ownerDid, required this.acls}) {
    this.ownerDid = hashDid(ownerDid);
  }

  /// Deserializes an [AccessListSet] from its JSON representation.
  factory AccessListSet.fromJson(Map<String, dynamic> json) {
    return _$AccessListSetFromJson(json);
  }

  /// Creates an [AccessListSet] that makes [ownerDid]'s resources public
  /// using [publicAclFlag].
  factory AccessListSet.toPublic({required String ownerDid}) {
    return AccessListSet(ownerDid: ownerDid, acls: publicAclFlag);
  }

  /// The ACL bitmask that grants public access.
  static final publicAclFlag = 524283;

  /// The ACL method identifier used when serializing this action.
  static final method = 'acl_set';

  /// The hash of the owner's DID.
  @JsonKey(name: 'did_hash')
  late final String ownerDid;

  /// The ACL bitmask to set as the owner's permissions.
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
