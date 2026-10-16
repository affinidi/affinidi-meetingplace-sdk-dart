import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/src/core/acl/legacy_acl_bitmask.dart';
import 'package:test/test.dart';

void main() {
  group('accessListModeFromLegacyBitmask', () {
    test('reads explicit deny from the public bitmask', () {
      expect(
        accessListModeFromLegacyBitmask(524283),
        AccessListMode.explicitDeny,
      );
    });

    test('reads explicit allow when the mode bit is clear', () {
      expect(
        accessListModeFromLegacyBitmask(0x7FFFA),
        AccessListMode.explicitAllow,
      );
    });
  });
}
