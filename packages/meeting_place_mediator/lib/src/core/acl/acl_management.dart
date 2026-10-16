import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'acl_body.dart';
import 'acl_time_utils.dart';

/// [AclManagement] is used for managing ACLs by controlling permissions and
/// access rights.
///
/// Only sent to mediators that do not serve the ACL Trust Tasks.
// ignore: deprecated_member_use
class AclManagement extends AclManagementMessage {
  AclManagement({
    required super.from,
    required List<String> to,
    required AclBody body,
    int expiresInSeconds = 60,
  }) : super(
         id: const Uuid().v4(),
         to: to,
         body: body.toJson(),
         expiresTime: getExpiresTime(expiresInSeconds),
       );
}
