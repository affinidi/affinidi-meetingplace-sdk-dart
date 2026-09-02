@Tags(['integration'])
library;

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../utils/approve_connection_request_fixture.dart';

void main() {
  test(
    "attaches Alice's onBuildAttachments result to ConnectionRequestApproval, "
    'received by Bob',
    () async {
      final attachment = Attachment(
        id: const Uuid().v4(),
        data: AttachmentData(base64: 'YWxpY2U='),
      );

      final fixture = await ApproveConnectionRequestFixture.create(
        aliceOptions: MeetingPlaceCoreSDKOptions(
          onBuildAttachments: (channel, getDidManager) async => [attachment],
        ),
      );

      expect(fixture.bobChannelAttachmentEvents, hasLength(1));
      expect(
        fixture.bobChannelAttachmentEvents.first.attachments,
        hasLength(1),
      );
      expect(
        fixture.bobChannelAttachmentEvents.first.attachments.first.id,
        equals(attachment.id),
      );
    },
  );

  test(
    "attaches Bob's onBuildAttachments result to ChannelInauguration, "
    'received by Alice',
    () async {
      final attachment = Attachment(
        id: const Uuid().v4(),
        data: AttachmentData(base64: 'Ym9i'),
      );

      final fixture = await ApproveConnectionRequestFixture.create(
        bobOptions: MeetingPlaceCoreSDKOptions(
          onBuildAttachments: (channel, getDidManager) async => [attachment],
        ),
      );

      expect(fixture.aliceChannelAttachmentEvents, hasLength(1));
      expect(
        fixture.aliceChannelAttachmentEvents.first.attachments,
        hasLength(1),
      );
      expect(
        fixture.aliceChannelAttachmentEvents.first.attachments.first.id,
        equals(attachment.id),
      );
    },
  );
}
