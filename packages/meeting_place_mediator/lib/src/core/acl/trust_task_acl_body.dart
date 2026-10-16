import 'package:didcomm/didcomm.dart';

import 'acl_body.dart';

/// An [AclBody] that can be sent to the mediator as a Trust Task.
///
/// Kept out of the public API so that apps implementing [AclBody] keep
/// compiling.
abstract interface class TrustTaskAclBody implements AclBody {
  /// Builds the mediator Trust Task that applies this ACL action, or `null`
  /// if the action changes nothing.
  ///
  /// **Parameters:**
  /// - [issuer]: The DID sending the task; must be the authenticated DID.
  /// - [mediatorDid]: The DID of the mediator the task is addressed to.
  TrustTaskDocument? toTrustTask({
    required String issuer,
    required String mediatorDid,
  });
}
