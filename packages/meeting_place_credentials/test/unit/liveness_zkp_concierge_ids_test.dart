import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

void main() {
  group('LivenessZkpConciergeIds', () {
    test('paused id pairs with request received id', () {
      const attachmentId = 'msg-1';
      final requestId = LivenessZkpConciergeIds.requestReceived(attachmentId);
      final pausedId = LivenessZkpConciergeIds.paused(
        forRequestNoticeMessageId: requestId,
      );
      expect(pausedId, 'zkp-paused-zkp-request-received-msg-1');
    });
  });
}
