import 'package:meeting_place_chat/meeting_place_chat.dart';
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
