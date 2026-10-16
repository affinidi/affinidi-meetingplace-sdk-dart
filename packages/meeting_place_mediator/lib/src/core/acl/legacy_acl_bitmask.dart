import 'package:didcomm/didcomm.dart';

// Bit of the ACL bitmask used by the legacy
// `https://didcomm.org/mediator/1.0/acl-management` protocol that selects the
// access-list mode.
const _accessListModeBit = 0;

/// Reads the access-list mode from a legacy ACL bitmask.
AccessListMode accessListModeFromLegacyBitmask(int acls) {
  return acls & (1 << _accessListModeBit) != 0
      ? AccessListMode.explicitDeny
      : AccessListMode.explicitAllow;
}
