/// Represents an ACL action payload that can be sent to the mediator.
abstract interface class AclBody {
  /// Serializes this ACL action into a JSON object.
  Map<String, dynamic> toJson();
}
