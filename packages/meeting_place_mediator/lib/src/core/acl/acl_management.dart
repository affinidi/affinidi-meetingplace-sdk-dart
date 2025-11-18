import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import 'acl_body.dart';
import 'acl_time_utils.dart';

/// [AclManagement] used for menaging ACLs by controlling permissions and
/// access rights.
class AclManagement extends AclManagementMessage {
  AclManagement({
    required super.from,
    required List<String> to,
    required AclBody body,
    int expiresInSeconds = 60, // TODO: make value configurable
  }) : super(
          id: const Uuid().v4(),
          to: to,
          body: body.toJson(),
          expiresTime: getExpiresTime(expiresInSeconds),
        );
}
